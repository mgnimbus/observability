# meta-monitoring optimization — findings & staged plan

> Generated 2026-06-07 during a guided session. The "Proposed" sections below were the original
> review. **Update (later same day): P1 is now IMPLEMENTED** — collectors migrated to v1beta1,
> tier-partitioned discovery applied, and kube-state-metrics fully migrated + verified in Mimir.
> See the bottom section **"P1 — IMPLEMENTED"** for the validated template and the rollout for the
> remaining targets. The other P-items (P2–P4) are still proposals.

Cluster at time of analysis: `meda-dev-koi-eksdemotest` · ap-south-2 · profile `obsrv`.

---

## Scrape topology (verified live, not assumed)

Two collectors:
- **`meta_metrics.yaml`** — DaemonSet, TA `allocationStrategy: per-node`, **no** prometheusCR.
  Jobs: `kubernetes-nodes` (kubelet), `kubernetes-nodes-cadvisor`, `kubernetes-service-endpoints`
  (service annotation `prometheus.io/scrape`).
- **`meta_ta.yaml`** — StatefulSet (HPA 1→10), TA `prometheusCR.enabled: true`.
  Jobs: `kubernetes-apiservers`, `kubernetes-services` (blackbox probe), `kubernetes-pods`
  (pod annotation), `prometheus-pushgateway`. **Plus** every ServiceMonitor/PodMonitor.

Live facts (`kubectl`):
- ServiceMonitors present: `loki`, 9×`mimir-*`, `opentelemetry-collector`.
- Pods annotated `scrape=true`: meta-monitoring (7), cert-manager (3), kube-system (2).
- Services annotated `scrape=true`: meta-monitoring (2 = kube-state-metrics, node-exporter), kube-system (1).
- **mimir / loki / otel-collector pods+services are NOT annotated** → scraped via ServiceMonitor only.
- **KSM + node-exporter pods are NOT pod-annotated** → scraped via service-endpoints only.

### ⚠️ Correction to the earlier verbal review
I initially asserted Mimir was being double-scraped (annotation job **and** ServiceMonitor).
**The live cluster disproves that** — Mimir carries no scrape annotations. The discovery
paths are currently **disjoint**, so there is **no active duplicate-sample condition**. The
"duplication" is *latent/architectural*, not a present bug. Honest correction kept on record.

### ✅ Series-level verification (kube/node/container metrics) — 2026-06-07
Verified in Mimir, not just from config (`max(count by <identity>)` = 1 means no duplicate series):
- `node_cpu_seconds_total` → `max(count by (instance,cpu,mode))` = **1**; single source
  `otel_collector_id="obsrv-metrics-new"`, job `kubernetes-service-endpoints` (node-exporter Service).
- `kube_pod_info` → `max(count by (namespace,pod))` = **1**; same single collector/job (KSM Service).
- `container_cpu_usage_seconds_total` → single collector `obsrv-metrics-new`, job `kubernetes-nodes-cadvisor`.
All kube/node/container families flow through the **daemonset** (`meta_metrics`) only; `meta_ta`
does not scrape them. **No duplication.** The ~209k active series is *volume* (cAdvisor/KSM
breadth), so the lever is the **P3 keep-list**, not dedup.

Tree-wide confirmation (2026-06-07): `count by (otel_collector_id, job) ({__name__=~"node_.*"})`
returns a **single** pair (`obsrv-metrics-new` / `kubernetes-service-endpoints`, 4972 series) →
one collector + one job per family ⇒ duplication structurally impossible. (Caveat for future me:
`count without(job, otel_collector_id)(...)` is a *bad* dup test — PromQL aggregation drops
`__name__`, so it counts metrics-per-target, not duplicate series. Use explicit
`count by (<full identity>)` instead.)

---

## Applied (safe, additive, in `meta_ta.yaml`)
1. Added `memory_limiter` processor (4200/1000/1s) + placed first in the metrics pipeline —
   parity with the daemonset; the autoscaled statefulset previously had **no** backpressure guard.
2. Added `GOMEMLIMIT=4250MiB` env — matches the daemonset; lets Go GC respect the 5Gi limit.
3. Removed the dead `sigv4auth` extension (defined but never listed in `service.extensions`;
   leftover from an Amazon Managed Prometheus `aps` experiment — exporter is OTLP to our endpoint).

## Proposed (needs your decision — NOT applied)

### P1 · Consolidate discovery (fixes the *fragility*, prevents future double-scrape)
Three discovery mechanisms (pod-annotation, service-annotation, prometheusCR) across two
collectors. The moment any target is annotated at both pod+service level, or gets an SM while
already annotated, silent double-scrape begins. Direction: **standardize on prometheusCR
(ServiceMonitor/PodMonitor)** and retire the annotation jobs, keeping only the infra jobs that
have no CRD equivalent (`kubernetes-nodes`, `kubernetes-nodes-cadvisor`, `kubernetes-apiservers`).
Migrate KSM/node-exporter/cert-manager to ServiceMonitors first, then drop the annotation jobs.
*Do not drop the annotation jobs before the SMs exist — that would lose coverage.*

### P2 · `exported_*` handling is done twice
`metricstransform` (`^exported_(.*)$` → `$1`) runs in **both** collectors, and `meta_metrics`
*additionally* relabels `exported_pod/node/namespace` → `pod/node/namespace` inside the
service-endpoints job. These overlap. Needs a careful pass with live label inspection before
changing — touching it blind can flip label outcomes. Left as-is for now.

### P3 · Cardinality keep-lists (the "for another time" item) — STAGED, commented
No `metric_relabel_configs` anywhere → 100% of every target's exposition is ingested. Live
active series at analysis time: **~209k** (`sum(cortex_ingester_memory_series)`). Top firehoses:
`kubernetes-nodes-cadvisor` (container_* per-container, churns on restart), `kubernetes-nodes`
(kubelet), KSM. Suggested **drop-list** to add per high-card job (review before enabling):

```yaml
# under the relevant scrape job:
metric_relabel_configs:
  # cAdvisor noise rarely dashboarded — drop the worst offenders
  - source_labels: [__name__]
    regex: 'container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|memory_failures_total|fs_.*)'
    action: drop
  # per-interface sandbox/pause container series
  - source_labels: [__name__, image]
    regex: 'container_.*;'           # container metrics with empty image (pause)
    action: drop
```

This is a **starting point**, intentionally conservative. Confirm which families you actually
query (check dashboard exprs) before enabling — dropping a metric blinds every panel/alert on it.

### P4 · Security (hardening pass, later)
Both collectors set `tls.insecure_skip_verify: true` on the OTLP export to
`otel.gowthamvandana.com`, despite mounting `otel-internal-ca-secret`. That defeats the CA you
ship. Switch to `ca_file: /etc/otel/certs/ca.crt` and drop `insecure_skip_verify` once cert SANs
are confirmed.

---

## Suggested apply order (when you're back, with `helm diff`/`kubectl diff` first)
1. `meta_ta.yaml` already-applied edits (memory_limiter, GOMEMLIMIT, sigv4auth removal) — lowest risk.
2. P1 discovery consolidation — migrate to SMs, *then* retire annotation jobs.
3. P3 cardinality keep-lists — after confirming query usage.
4. P4 TLS hardening.

---

# P1 — IMPLEMENTED: validated ServiceMonitor template + per-target rollout (2026-06-07)

P1 is no longer a proposal. The v1beta1 collector migration + a **single prometheusCR discovery
plane** are applied and the first target (**kube-state-metrics**) is migrated and **verified
end-to-end in Mimir**. This section is the durable, multi-cluster recipe for finishing the rest.

## The design — ONE prometheusCR plane (not two)
An earlier draft partitioned discovery across both TAs by an `obsrv.io/scrape-tier` label to keep
node exporters on the daemonset and stop `otel_collector_id` from flipping. **That was
over-engineering and has been reverted.** Why it was unnecessary, verified live 2026-06-07:
- `otel_collector_id` (= which collector scraped the series) is **emitted but consumed by
  nothing**: of 35 dashboards, **0** reference it (the OtelCol dash keys off
  `job`/`receiver`/`processor`/`exporter`; the dotdc k8s dashboards off `cluster`/`namespace`/
  `node`/`pod`), and there are **0 alert rules**. So a collector flip is invisible.
- The IaC targets **fresh** clusters (the dev cluster is rebuilt daily); a fresh cluster has no
  historical series to "drift" from — node exporters are simply born on `obsrv-ta`.

So the rule is now trivial — **enable a ServiceMonitor anywhere and the statefulset TA scrapes it:**

| TA | mode | `serviceMonitorSelector` | owns |
|----|------|--------------------------|------|
| `obsrv-ta` | statefulset (HPA 1→10) | `{}` (match-all) | **every** ServiceMonitor: loki, mimir/*, KSM, node-exporter, cert-manager, … |
| `obsrv-metrics-new` | daemonset (per-node) | *prometheusCR disabled* | only its **static** node jobs (`kubernetes-nodes`, `-cadvisor`) via `allocationStrategy: per-node` |

No tier label, no `NotIn` semantics, no "nil selector selects none" trap — one place owns CRD
discovery. Two prometheusCR TAs would have needed disjoint selectors to avoid double-scrape; one
plane deletes that entire failure mode.

**Caveat (don't re-add the partition for the wrong reason):** per-node scraping is a real lever —
but for **scale** (thousands of node-exporters across a sharded fleet), *not* for
`otel_collector_id`. At this platform's size a single sharded statefulset handles all node-exporter
endpoints fine. Re-introduce a node-tier partition only if/when node count makes central scraping
the bottleneck — and document it as a scale decision, not a drift one.

## Why two collectors, not one (decided 2026-06-07)
We evaluated collapsing to a single collector. Outcome: **keep two**, split by *scrape topology*,
with the single prometheusCR plane living on the statefulset:
- **daemonset** (`obsrv-metrics-new`, per-node) — node-local jobs only: `kubernetes-nodes`
  (kubelet) + `kubernetes-nodes-cadvisor`. Scales with node count; keeps the heaviest/churniest
  targets node-local.
- **statefulset** (`obsrv-ta`, consistent-hashing + HPA) — `kubernetes-apiservers` + the single
  prometheusCR plane (every ServiceMonitor). Scales with scrape load.

A single **daemonset** cannot be the sole scraper: the TA `per-node` strategy — the only reason to
use a daemonset — *"assigns targets to the collector on the same node … **ignoring targets not
assigned to a Node**, such as **control plane components**"* (OTel Operator docs). So
`kubernetes-apiservers` would be **silently dropped**. Forcing a daemonset to scrape everything
means switching it to `consistent-hashing`, at which point it's a Deployment-shaped daemonset
(pod-per-node, no node-locality benefit, scales with node count not load). A single **statefulset**
*is* viable (consistent-hashing + HPA, min 2 for HA) but we kept the daemonset for node-local
efficiency. **Net: two collectors, one prometheusCR plane.**

## Two independent switches per target (the mental model)
Each migration is **(1) create the SM/PM** (any SM is picked up by the single statefulset plane —
no label needed), and **(2) stop the old annotation scrape**. They are *separate knobs* and (2)
**differs per chart** — that is the only fiddly part:

| Target | What adds `prometheus.io/scrape` today | Switch (2): de-annotate | Switch (1): create SM/PM |
|--------|----------------------------------------|-------------------------|--------------------------|
| **kube-state-metrics** ✅done | chart top-level `prometheusScrape: true` (Service) | `prometheusScrape: false` | `prometheus.monitor.enabled: true` + `honorLabels: true` |
| **node-exporter** | chart `service.annotations` default (`prometheus-node-exporter` 4.45.0 line 145) | `service.annotations: {}` | `prometheus.monitor.enabled: true` + **`relabelings` to set `node`/`instance`** (no `honorLabels` — it exposes its own labels) |
| **kube-dns / CoreDNS** | **EKS addon-managed** Service (`:9153`) — *not our chart* | can't cleanly per-target (addon reverts `kubectl annotate`); relies on **Wave 5** job-delete | hand-author SM in `kube-system` → `kube-dns` Service port `metrics` |
| **cert-manager** | chart `prometheus.enabled: true` legacy **pod** annotations | switching to the native monitor drops them | `prometheus.podmonitor.enabled: true` — **PodMonitor, needs the CRD** (see fork below) |
| **aws-lb-controller** | chart default pod annotation (our `values.yaml` doesn't set it) | add `podAnnotations: {}` override in `_1.2.1load_balancer/manifests/values.yaml` | `serviceMonitor.enabled: true` |
| **cop-logs** | **our** `otel_meta_cop_logs.yaml` `podAnnotations` (lines 11–14) | delete those 4 lines | chart `serviceMonitor.enabled: true` (or hand-author SM on the `:8888` metrics Service) |
| **metrics-server** | **nothing — not scraped today** | n/a | *optional* `serviceMonitor.enabled: true` (this **adds** coverage, it is not a migration) |

Notes that bit us, so they're recorded:
- **The de-annotation knob is never `service.annotations` for KSM** — it's the top-level
  `prometheusScrape`. Each chart hides this switch somewhere different; check the rendered object
  (`kubectl get svc/pod -o jsonpath='{.metadata.annotations}'`) to confirm it's gone, don't assume.
- **`honorLabels: true` only where the exporter exposes *another object's* identity** (KSM emits
  the described pod/ns/node). Plain exporters (node-exporter) expose their own labels → no
  `honorLabels`; instead add `relabelings` to populate `node`/`instance` (replaces the old
  `__meta_kubernetes_pod_node_name → node` relabel the annotation job did).
- Switch (2) can *also* be handled globally by **Wave 5** (deleting the two annotation jobs). Prefer
  de-annotating at source where the knob is ours (zero overlap window); lean on Wave 5 only for the
  EKS-managed `kube-dns`.

## Fork: install the PodMonitor CRD? (recommended — resolves two blockers at once)
`PodMonitor` CRD is **absent** today. That single fact:
1. forces `kubernetes-pods`-annotation charts onto hand-authored SMs, and
2. makes cert-manager's **chart-native** path (`prometheus.podmonitor.enabled`) unusable, and
3. is **also** why `observability.metrics.enableMetrics` never produced the collectors' own `:8888`
   self-telemetry SMs — the operator logs `prometheus-cr-availability: 0` and skips creation.

**Recommended:** install the PodMonitor CRD (`_1.3_crd` — there is a commented-out `pod_monitor`
resource; add `pod-monitor.yaml`, `server_side_apply`). Then:
- the operator auto-creates the `obsrv-ta` + `obsrv-metrics-new` self-telemetry SMs (closes the
  deferred item) — they land on the single statefulset plane;
- cert-manager uses `prometheus.podmonitor.enabled: true`;
- set **`podMonitorSelector: {}`** on the statefulset TA (it is currently unset, and a nil
  selector selects *none*) so the new PodMonitors are actually discovered.

Alternative (no CRD): hand-author a ServiceMonitor for cert-manager (needs a metrics Service on
`:9402` — newer charts don't ship one, which is *why* they moved to PodMonitor). Less clean; only
take it if adding the CRD cluster-wide is unacceptable.

## Rollout order (each step: `kubectl diff`/`helm diff` → confirm → apply → verify in Mimir)
1. ✅ **node-exporter** — `prometheus.monitor.enabled` (SM, *not* PodMonitor) + `service.annotations: {}`
   to drop the chart-default `prometheus.io/scrape`. Verified: job `prometheus-node-exporter` up,
   `kubernetes-service-endpoints` duplicate of `node_*` gone (was 51+51 → 51).
2. ✅ **cop-logs** (cluster, our values — delete annotation lines + chart SM).
3. ✅ **aws-lb-controller** — `serviceMonitor.enabled`; job `aws-load-balancer-controller` up.
4. ✅ **cert-manager** — chart key is lowercase **`prometheus.servicemonitor.enabled`** (camelCase
   `serviceMonitor` is silently ignored → no SM). Done via SM, **no PodMonitor CRD fork needed**;
   `cert-manager/cert-manager` SM created, job `cert-manager` `up==1`. The CRD fork is now only
   relevant for the operator's own self-telemetry PodMonitors (separate, optional).
5. **kube-dns/CoreDNS** SM (node) — pair with Wave 5 since it can't self-de-annotate. **Deferred**
   (see "Deferred — do later" above).
6. **Wave 5 — retire the annotation jobs:** delete `kubernetes-pods` (`meta_ta.yaml`) and
   `kubernetes-service-endpoints` (`meta_metrics.yaml`). **Keep** the infra jobs with no CRD
   equivalent: `kubernetes-nodes`, `kubernetes-nodes-cadvisor`, `kubernetes-apiservers`.

**Removed as dead config (2026-06-07):** two never-wired-up probe jobs in `meta_ta.yaml`, each
verified unused **3 ways** (Mimir `up{job=...}` returns no data · the job's own metric = 0 · the
source object/exporter doesn't exist):
- `kubernetes-services` (blackbox `http_2xx` probe) — `probe_success` empty, **0** services carry
  `prometheus.io/probe: "true"`, and **no `blackbox` exporter** is deployed (the job relabels
  `__address__ → blackbox`, which resolves to nothing).
- `prometheus-pushgateway` — `push_time_seconds` empty, **0** services carry
  `prometheus.io/probe: pushgateway`, and **no pushgateway** is deployed.

`meta_ta.yaml` now carries only `kubernetes-apiservers` + `kubernetes-pods` static jobs (the
latter retired in Wave 5) plus the prometheusCR plane.

## Deferred — do later (noted 2026-06-07)
Both are explicitly parked; everything else in this consolidation is migrated + verified.

- **(c) `kubernetes-apiservers` job — `up==0`.** Reachable on EKS (kube-apiserver `/metrics` via
  `kubernetes.default.svc:443`); down purely because the collector SA lacks the non-resource grant
  `{nonResourceURLs: ["/metrics"], verbs: ["get"]}`. **Verified nothing consumes it:** the
  server-side apiserver series (`apiserver_request_total`, `apiserver_request_duration_seconds`,
  `apiserver_current_inflight_requests`, APF `flowcontrol_*`, `etcd_object_counts`) = **0 series**;
  **0 dashboards** reference apiserver; **0 alert rules** exist. Decision when we return: either
  **(i)** add the ClusterRole grant *when we actually build an API latency/error + APF-throttle
  panel*, or **(ii)** drop the job so we don't carry a permanently-red target. EKS caveat: only the
  apiserver is exposed — scheduler / controller-manager / etcd server metrics are managed-plane and
  unreachable (those kube-prometheus panels stay empty regardless).
- **kube-dns / CoreDNS** — the **last** Service still carrying `prometheus.io/scrape: "true"`
  (`kube-system/kube-dns`, EKS addon-managed `:9153`). Can't self-de-annotate (addon reverts
  `kubectl annotate`). Plan unchanged: hand-author an SM in `kube-system` selecting the `kube-dns`
  Service port `metrics`, then retire `kubernetes-service-endpoints` via Wave 5 (after this it has
  no other members).

## Per-target verification (grafana MCP, datasource `mimir`) — the exact checks that passed for KSM
- **No new series identity / dedup:** `max(count by (<full identity>) (<metric>))` must stay **1**
  (e.g. KSM `count by (namespace,pod)(kube_pod_info)`; node-exporter `count by (instance,cpu,mode)
  (node_cpu_seconds_total)`).
- **Single collector now:** `count by (otel_collector_id)(<metric>)` → one value, `obsrv-ta`.
  Node families (KSM/node-exporter/CoreDNS) **flip** `obsrv-metrics-new`→`obsrv-ta` as they
  migrate — that is **expected and harmless** (verified: nothing consumes `otel_collector_id`).
- **Job hygiene:** `count by (job)(<metric>)` → exactly one expected job; the old
  `kubernetes-service-endpoints`/`kubernetes-pods` copy ages out within **~5 min staleness** after
  de-annotation (don't mistake the staleness window for a persistent double-scrape).
- **No coverage loss:** `count(up == 0)` does not increase; `sum(cortex_ingester_memory_series)` ≈ flat.
- **k8s-level proof the de-annotation took:** `kubectl -n <ns> get svc|pod <name>
  -o jsonpath='{.metadata.annotations}'` shows no `prometheus.io/scrape`.
