# OTel Collector Golden Template

One standard, four-tier OpenTelemetry Collector architecture for every EKS cluster in the fleet
(200+ clusters, 5–200 nodes each). Plain manifests, ArgoCD-ready: every file is **byte-identical
across clusters** except `00-fleet-identity.yaml` (two values). No Helm, no Kustomize.

```
10  otel-node-metrics     DaemonSet     kubelet + cAdvisor, scraped LOCALLY on :10250 (no API-server proxy)
20  otel-cluster-metrics  StatefulSet   ServiceMonitors + PodMonitors + apiserver, TA-sharded, HPA 2–10
30  otel-logs             DaemonSet     /var/log/pods tail, checkpointed, severity-filtered
40  otel-events           Deployment×1  cluster Events, Warning+ only, STRICT singleton
50  otel-collector-self   SvcMonitor    :8888 self-telemetry of all four tiers, cardinality-trimmed
```

All telemetry is enriched with `k8s.cluster.id = ${CLUSTER_NAME}` and exported to
`https://otel.gowthamvandana.com:443` (OTLP gRPC, snappy) with header `X-Scope-OrgId: ${ORG_ID}`.

## Prerequisites (per cluster)
1. **OpenTelemetry operator** (+ cert-manager) — all tiers are `OpenTelemetryCollector` CRs.
2. **prometheus-operator CRDs**: ServiceMonitor **and** PodMonitor (the Target Allocator watches
   both; a missing PodMonitor CRD breaks the TA's informers). Vendored at v0.91.0 in `_1.3_crd/`.
3. Outbound 443 to the OTLP endpoint.

## Adopting
1. Copy the directory; edit **only** `00-fleet-identity.yaml`: set `CLUSTER_NAME` (unique cluster
   id) and `ORG_ID` (your tenant). ArgoCD ApplicationSets can patch the ConfigMap per cluster.
2. Sync. Wave 0 = namespace/identity/PriorityClass/RBAC; wave 1 = collectors + ServiceMonitor.
3. Run the verification queries below.

## The ownership contract (anti-duplication — read this)
Tier 2 discovery is **match-all**: any ServiceMonitor/PodMonitor your team creates is scraped
automatically. The flip side: these targets are **platform-owned by this template** — creating
your own monitors or shippers for them double-ingests fleet-wide:

- kubelet & cAdvisor (owned by tier 1 — e.g. kube-prometheus-stack's kubelet ServiceMonitor would
  ingest every kubelet series twice)
- kube-apiserver (tier 2's static job)
- container/pod logs (tier 3 — no Fluent Bit / promtail side-by-side)
- cluster Events (tier 4 — and never raise its `replicas`)
- collector self-telemetry (file 50)

Run **one** scrape plane per cluster. If a legacy agent exists, disable it before syncing this.

## Anti-explosion design (what protects the backend ×200 clusters)
- **Scrape guardrails** (tiers 1+2 `global`): `sample_limit: 300000`, `label_limit: 60`, label
  name/value length caps, `body_size_limit: 50MB`. A pathological `/metrics` fails *its own*
  scrape (`up == 0`, alertable) — it cannot melt the shared pipeline.
- **No node-label labelmap** on kubelet/cadvisor; node identity is a single `node` attribute.
- **`(apiserver|etcd)_.*` dropped** at the apiserver scrape (largest cardinality source on EKS;
  the control plane is AWS-managed anyway).
- **Logs ship zero app-field attributes**: JSON bodies are parsed only into a scratch field to
  read `level`, then the scratch is removed. No pod labels/annotations extraction (annotations can
  carry kilobyte `last-applied` blobs).
- **trace/debug dropped, gated on parsed severity** (see severity contract).
- **Events are Warning+ only** and collapsed to compact single lines (no managedFields JSON).
- **Self-telemetry trimmed** at the scrape (drops the ~23-series/pod batch histogram et al.) while
  keeping the OtelCol dashboard anchors (`process_uptime`, `process_memory_rss`) and every
  actionable signal (refused/dropped/send_failed/queue).
- **Multi-line joining is capped** (`max_batch_size: 100`) — an app cannot glue unbounded output
  into one mega-record.

## Anti-duplication design
- **file_storage checkpoints** on a tier-scoped hostPath (`/var/lib/otelcol/otel-logs`): restarts
  resume at the exact offset — no re-reads. `start_at: end` ⇒ first rollout doesn't backfill.
- **filelog `retry_on_failure`**: memory pressure becomes *read backpressure* (files persist on
  disk) instead of drops — and no duplicate-prone persistent sending queue is used. Delivery
  stance: **bounded loss is preferred over duplication** (memory queue only).
- **Self-log exclusion**: tier 3 never reads its own pod logs (export-error feedback loop).
- **Singleton events** by structure, not by tuning.
- **TA consistent-hashing** assigns each target to exactly one tier-2 replica.
- The optional `k8s_cluster` receiver (file 40, commented) must NEVER run alongside
  kube-state-metrics — pick one source of cluster-state metrics.

## Severity contract (for app teams)
trace/debug dropping engages **only** when a record's severity is parseable: JSON logs with a
`level` field, or text logs containing `level=<word>`. Anything unparseable always passes
(`severity_number > 0 and severity_number < 9` — the `> 0` guard means "unknown ≠ droppable",
and `< 9` keeps INFO, which IS severity 9). Emit a `level` to benefit from the noise gate.

## Corrections vs. the original spec (bugs we hit live — do not "fix" these back)
| Spec said | Reality |
|---|---|
| `combine` operator | Doesn't exist (`unsupported type 'combine'`). CRI 16KB partial stitching is built into the `container` operator; multi-line app joining is `recombine`. |
| just mount file_storage hostPath | The pod must run as **root** (`runAsUser: 0`) or it dies with `permission denied` on the checkpoint db. |
| `insecure_skip_verify` for kubelet | TLS ≠ authz: the scrape also needs RBAC **`get nodes/metrics`** + the SA bearer token, or it's a 403. |
| filter events on `type` | `body["type"]` is the watch verb. Severity (Normal/Warning) is `body["object"]["type"]`. |
| drop `severity_number <= 9` | Unparsed severity is **0** → `<= 9` drops *everything* (blackout), and 9 is INFO. Use the guarded form above. |
| (chart) `node_from_env_var: ${env:K8S_NODE_NAME}` | The field takes the env var **NAME** (`K8S_NODE_NAME`); an expanded value silently disables the node filter. |

## Sizing (per pod; GOMEMLIMIT ≈ 80% of limit; memory_limiter just below GOMEMLIMIT)
| Tier | Requests | Limit | GOMEMLIMIT | memory_limiter |
|---|---|---|---|---|
| node-metrics (DS) | 50m / 500Mi | 1 / 2Gi | 1600MiB | 1500 + 300 spike |
| cluster-metrics (STS ×2–10) | 100m / 750Mi | 1 / 5Gi | 4250MiB | 4250 + 850 spike |
| logs (DS) | 200m / 400Mi | 1 / 1Gi | 800MiB | 800 + 200 spike |
| events (Deploy ×1) | 50m / 128Mi | 500m / 512Mi | 400MiB | 450 + 100 spike |

Daemonsets roll at `maxUnavailable: 10%` (a 200-node rollout in ~10 steps, not 200), tolerate all
`NoSchedule` taints, run only on linux nodes, and carry PriorityClass `otel-collector-priority`
(value 1000000) so the telemetry plane isn't the first eviction under pressure.

## Verification (per cluster after sync)
```promql
# every tier up, and each scrape target owned by exactly one collector
up{job=~"otel-.*"} == 1
count by (job) (otelcol_process_uptime_seconds_total)        # exactly 4 jobs
count by (otel_collector_id, job) (up)                       # one owner per job

# nothing being dropped or failing to export
rate(otelcol_exporter_send_failed_metric_points_total[5m]) == 0
rate(otelcol_exporter_send_failed_log_records_total[5m])   == 0
rate(otelcol_processor_dropped_log_records_total[5m])      == 0
```
In Loki: app log bodies are clean (no CRI `... stdout F` prefix), INFO present / DEBUG absent for
a level-emitting app, events are compact `Warning <Reason> <Kind>/<name>: <message>` lines.
