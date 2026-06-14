# KNOWLEDGE.md — LGTM/OTel metrics cardinality: a correctness runbook

> **This is not a recap — it is the minimum complete information to reproduce the work correctly the
> first time, with every mistake we hit encoded as a guardrail.** Read it before touching anything.
> All company-specific names are `<PLACEHOLDERS>`; the real sandbox values live only in the
> **Reference implementation** appendix at the bottom (clearly labelled — never a requirement).

---

## 0. The platform model (assumed)
App teams **opt-in** by deploying an OTel collector template on **their own EKS cluster (10–200 nodes)**
that ships to a **central, shared Mimir**, isolated per team by **`X-Scope-OrgID`** (one tenant per
team). Two jobs:
- **Track A — the template** newer teams deploy (greenfield): must be hardened *and* low-cardinality
  out of the box.
- **Track B — reduce cardinality on the ~100 existing clusters** (brownfield): analyze per tenant,
  recommend reversible drops, validate.

The central Mimir is the shared blast surface: one team's runaway cardinality is everyone's incident.
That is *why* this discipline matters.

---

## 1. The 4-tier collector pattern
Byte-identical per cluster except a `fleet-identity` ConfigMap (`CLUSTER_NAME`/`ORG_ID`):

| Tier | Workload | Scrapes | Why this shape |
|---|---|---|---|
| node metrics | **DaemonSet**, no TA | this node's kubelet `:10250` `/metrics` + `/metrics/cadvisor` (static `${env:HOST_IP}` target) | shards by node naturally; **no `role: node` SD** (every pod watching all nodes = N×N watches ×100 clusters); direct kubelet, not apiserver-proxy (proxying every scrape through the control plane = throttling incident) |
| cluster metrics | **StatefulSet + Target Allocator** (HPA 2→10, consistent-hashing) | apiservers (static) + **every ServiceMonitor/PodMonitor** (`serviceMonitorSelector: {}` + `podMonitorSelector: {}`) | TA sharding needs stable pod identity (statefulset). A daemonset-only plane **silently drops control-plane targets** (the `per-node` TA "ignores targets not assigned to a Node") |
| gateway | **Deployment** (autoscaled), central | receives OTLP from the per-cluster collectors, `prometheusremotewrite` → Mimir with `resource_to_telemetry_conversion` | the multi-tenant chokepoint; **do not put per-team logic here** (§4) |
| logs / events | DS / **Deployment×1** | container logs / k8s events | events MUST be a singleton — cluster-scoped, any autoscaled/DS collector duplicates ×replicas |

---

## 2. The 4 `/metrics` exposition archetypes
Knowing the archetype tells you the data source, scrape path, and identity handling *before* you debug:
1. **Host exporter** (node-exporter): subject = the node; source = kernel `/proc`+`/sys`; direct `:9100`;
   `instance`=podIP; **no `honorLabels`**. Counters live in the kernel → survive a pod restart (only a
   node reboot resets).
2. **Foreign-object exporter** (kube-state-metrics): subject = *other* k8s objects; source = the API
   **watch cache** (0 API calls per scrape); direct `:8080`; **needs `honorLabels: true`** (it carries
   the *described* object's namespace/pod/node).
3. **App self-instrumentation** (Mimir/Loki `cortex_*`/`loki_*`): subject = the app's own internals;
   in-process `client_golang`; counters **reset on restart** and `rate()` heals it.
4. **Kubelet-embedded** (cAdvisor `container_*`): subject = each container; source = kernel **cgroups**;
   served by the kubelet at `/metrics/cadvisor`.

> **Durable rule: a metric NAME never identifies a source — `job`+`instance` do.**
> (`promhttp_metric_handler_requests_total` shows up under every Go exporter, not one scraped 4×.)

---

## 3. The cardinality lever ladder (ranked, use in this order)
1. **Exporter-native** — KSM `--resources` + `--metric-denylist`; node-exporter `--no-collector.*` +
   `--collector.*.exclude`. The component **never generates** the series (also saves its CPU/mem).
   *Conservative* — undo = redeploy.
2. **ServiceMonitor / PodMonitor `metricRelabelings`** — the reversible gray area ("most don't need,
   some might"). Component still exposes at `/metrics`; just not ingested. Flip back = edit the regex.
3. **cAdvisor keep-list** — cAdvisor has **no native knob** (it's the kubelet's built-in set) →
   `metric_relabel_configs` keep-list at the scraping collector is the *only* lever.
4. **Label width / dedup** (§4) — cuts per-series bytes + index memory, not series count.
5. **Churn labels** (`uid`, cAdvisor `id`/`name`/`image`, `k8s_pod_uid`) — labeldrop; cuts new-series
   growth over time.

**Prefer `--metric-denylist` over a hand-built `--metric-allowlist`** when the consumer set is large:
an allowlist silently blinds a consumed panel **or a ruler dependency** (e.g. the Mimir ruler needs
`kube_deployment_spec_replicas`/`kube_statefulset_replicas`, which are *not* dashboard-consumed).
Denylist = you can only break what you explicitly name. Always document the **get-it-back path**
(port-forward the source `/metrics` → widen the helm → re-baseline).

---

## 4. The 3-way label stacking + dedup  ⭐
Every scraped series accumulates ~24–33 labels because **three sources stack**:
1. **Prometheus target labels** — `instance, job, pod, namespace, container, endpoint`.
2. **`k8s_*` resource attrs** — `k8s_pod_name, k8s_namespace_name, k8s_node_name, k8s_container_name,
   k8s_pod_uid, k8s_daemonset_name, k8s_replicaset_name` (+ `k8s_statefulset_name`).
3. **Gateway `resource_to_telemetry_conversion` flatten** — `service_*, server_*, url_scheme,
   otel_scope_*`.

Net = **triple coverage**: `namespace`==`k8s_namespace_name`, `pod`==`k8s_pod_name`,
`instance`==`service_instance_id`==(`server_address`+`server_port`), `container`==`k8s_container_name`,
`job`==`service_name`. Plus churning `k8s_pod_uid`.

**The fix — at the PER-TEAM collectors, NOT the shared gateway:**
- A `resource` processor that **deletes** the redundant resource attrs *before* the OTLP export:
  `k8s.pod.name, k8s.namespace.name, k8s.node.name, k8s.container.name, k8s.pod.uid, k8s.daemonset.name,
  k8s.replicaset.name, k8s.statefulset.name, server.address, server.port, url.scheme`.
- A `transform` processor (`context: scope`, `set(name,"")` + `set(version,"")`) to clear the
  instrumentation scope → the gateway PRW emits empty `otel_scope_*` → **Mimir drops empty labels**.
- **KEEP**: `service.name`/`service.instance.id`/`service.version` (the OtelCol dashboard reads them),
  `k8s.cluster.id`, `otel_collector_id`, and the plain target labels.

> **KEY RULE: do label hygiene at the producer (per-team collector), NEVER at the shared gateway.** The
> gateway is multi-tenant — a delete there adds hot-path overhead for everyone and strips resource
> attrs other teams legitimately use. (We planned it at the gateway first; corrected to the collectors.)

> The plain target labels (`namespace`/`pod`/`instance`) are **datapoint** attributes already; the
> `k8s_*`/`service_*`/`server_*` are **resource** attributes flattened by `resource_to_telemetry`.
> Deleting the resource attrs leaves the plain labels intact. If any survive after apply, they were
> datapoint-level → delete via an `attributes` processor (underscore keys) instead. Verify per §6.

---

## 5. The OTLP-histogram rule  ⭐
**You cannot drop only `_bucket` in an OTLP pipeline.** The OTel prometheus *receiver* reassembles
`_bucket`/`_sum`/`_count` into one OTLP histogram; if `_sum`/`_count` survive, the gateway PRW
`add_metric_suffixes` **re-emits a degenerate `_bucket{le="+Inf"}`**. A `_bucket`-only drop went 978→353
(not →302) for us. **Drop the whole family** `_(bucket|sum|count)` (the receiver then assembles nothing),
or filter the OTLP metric by name. Histograms are 0-or-all in this pipeline.

---

## 6. Consumption-gating — the SOURCE OF TRUTH is the REPO, not the cluster  ⭐
Dashboards are usually JSON in the repo, pushed by the **Terraform Grafana provider** (`grafana_dashboard`,
`overwrite=true`) **straight to the API — not ConfigMaps/sidecar**. So a `kubectl get cm` scan is a
**FALSE NEGATIVE** (it told us "0 dashboards" while 31 existed). Gate every drop:
1. `grep -rlE '<metric_>' <dashboards-repo>/` — fast, authoritative, offline.
2. Grafana MCP cross-check (`search_dashboards` + `get_dashboard_panel_queries`; an empty-query search
   returns stale phantoms — confirm with a targeted search).
3. Mimir **ruler** rules (recording + alerting).

Match at **PromQL level** — `by(<l>)`, `{<l>=`, `group_left(<l>)` — **NOT substring grep**. Short label
names (`id`/`name`/`uid`/`service`) false-positive across panel ids / field names / datasource uids in
dashboard JSON; we got 47–52 bogus "hits" that way. **And verify-consumption BEFORE adding any
complexity to preserve a label** — we once built a two-TA partition to protect `otel_collector_id`,
which 0 dashboards read.

---

## 7. Validation discipline (every change)
- `baseline.sh` before → change → after → `diff -u`.
- `scrape_samples_post_metric_relabeling` is **staleness-free**; `count()` lags ~5 min (a series is
  counted while it still has a sample in the lookback) → re-check count-based numbers after the window.
- `count(up==0)` unchanged (no scrape broke).
- No dup: `max(count by(<full identity>)(<metric>)) == 1`.
- Joins still resolve: `<m> * on(namespace,pod) group_left(node) kube_pod_info`.
- `count by(otel_collector_id)(<metric>)` → one collector (a family flipping collectors during a
  migration is expected/harmless if nothing reads the label).
- Live-query: Grafana MCP (datasource `mimir`) OR curl fallback (`svc/mimir-nginx`, `X-Scope-OrgID`;
  quoting trap — plain `"` not `\"` inside a single-quoted bash arg). **Prefer trimmed CLI
  (`curl|jq|head`) for token economy; MCP when leaner/safer.**

---

## 8. Spillage classes (a family escaping a name-regex drop via a different prefix)
`node_authorizer_` (apiserver-sourced, dodges `(apiserver|etcd)_.*` via the `node_` prefix — a histogram
= 150 series, not 3), `authentication_`/`authorization_` (218), `apiserver_` re-exposed on the **kubelet**
job (136), `kube_apiserver_clusterip/nodeport_allocator_*` (dodges via the `kube_` prefix). Fix: an
explicit include in the regex, or flip the job to a **keep-list**. The `apiserver_`/`etcd_` family alone
was **~56% of all ingest** on one cluster — dropped after 0-consumption proof.

---

## 9. Hardening every template MUST ship (don't bolt on late)
- prometheus **global guardrails**: `sample_limit`, `label_limit`, `label_name_length_limit`,
  `label_value_length_limit`, `body_size_limit` — a pathological `/metrics` fails ITS OWN scrape
  (`up=0`, alertable) instead of melting the shared pipeline. Essential on a match-all plane.
- `health_check` extension on **`0.0.0.0:13133`** (kubelet probes can't reach localhost) → the operator
  wires liveness/readiness off it.
- `nodeSelector: kubernetes.io/os: linux` (a broad `NoSchedule` toleration + no selector = the linux
  image crashloops on Windows nodes).
- `priorityClassName` (+ create the PriorityClass) — eviction protection.
- DaemonSet `updateStrategy.rollingUpdate.maxUnavailable: 10%` (default 1 = serial rollout at 200 nodes).
- TA `minReplicas: 2` (no scrape gap on restart).

---

## 10. OTel-template BUILD gotchas (Track A — these fail SILENTLY)
- **daemonset Helm chart renders no Service/SM** (`serviceMonitor.enabled` is a silent no-op there) →
  use **PodMonitor** (needs the **PodMonitor CRD** installed **and** `podMonitorSelector: {}` — an absent
  selector selects NONE). Operator CRs get a monitoring Service but no SM unless the operator feature-gate
  is on → one explicit SM selecting `operator.opentelemetry.io/collector-service-type: monitoring`.
- **distinct `job` per collector** = `service.telemetry.resource."service.name": <id>` (default
  `otelcol-contrib` collapses every collector's self-telemetry). `:8888` binds pod-IP → `kubectl
  port-forward` (loopback) can't reach it; a real scrape (pod IP) can.
- **never drop `otelcol_process_uptime`/`otelcol_process_memory_rss`** — the OtelCol dashboard's `job`
  template var keys on them (drop → blank dashboard). Same warning for `target_info` (used as an `or`
  fallback there) — and `target_info` from a multi-replica gateway causes Mimir
  `err-mimir-sample-out-of-order` (shared synthetic series, racing writers) → set
  `target_info: {enabled: false}` on the gateway PRW.
- **`templatefile()` templates COMMENTS too** — a literal `${` in a YAML comment breaks the whole render
  (terraform `validate` misses it; only `plan`/`apply` catches). Escape `$${`. **Two-layer `$`:**
  metricstransform group ref is `$${1}` in plain YAML / `$$${1}` under templatefile; OTTL statements must
  be **single-quoted** in YAML (a `: ` inside breaks the YAML).
- **validate offline** with the real `otelcol-contrib <ver> validate --config=<rendered .spec.config>`
  (stub the SA token/CA + the file_storage dir — both are stat'd) — it builds the filelog operator chain
  and parses OTTL, far deeper than `kubectl --dry-run`.
- **logs traps**: filelog multiline op is `recombine` (not `combine`); `severity_number <= 9` drops 100%
  of app logs when severity was never parsed (unset=0) and 9=INFO anyway → guard `> 0 and < 9` + actually
  parse severity; pod runs as **root** for hostPath `/var/log`; exclude self-logs (feedback loop);
  `k8sattributes node_from_env_var` takes the env var **NAME** not its value; prefer the upstream
  `container` operator over hand-rolled recombine/parser chains; operator CR (no chart presets) + drop
  `resourcedetection` = lean Loki labels by construction.
- **direct-kubelet scrape RBAC** = `get nodes/metrics` (the apiserver-proxy path used `nodes/proxy`).
- **OTLP export `no children to pick from`** = the export endpoint **doesn't resolve / has no backend**
  (NOT TLS, NOT auth) — classic Route53/NLB gap on a rotated cluster. **Healthy pods + zero data = a
  data-layer failure** (export or scrape) — never trust pod status as "working."

---

## 11. MISTAKES LEDGER — do not repeat (each line = the rule it teaches)
1. Planned label dedup at the **shared gateway** → corrected to per-team collectors. *Fix at the producer
   on any multi-tenant plane.*
2. Dropped only histogram `_bucket` → +Inf reconstruction (978→353). *Whole-family `_(bucket|sum|count)`.*
3. Consumption grep on short names (`id`/`name`/`uid`) = false positives. *Match at PromQL level.*
4. Asserted stale cluster state twice (`podMonitorSelector` nil; PodMonitor CRD absent) from a stale doc /
   `kubectl … 2>/dev/null`. *Verify CRDs/selectors live (`kubectl get crd`/`api-resources`); never suppress
   the stderr that signals absence.*
5. `kubectl get cm` for dashboard consumption = false negative (TF-provider dashboards). *Grep the repo.*
6. Over-engineered a two-TA partition to protect an unconsumed label. *Verify-consumption first.*
7. `otel_scope_*` + `X_Scope_OrgId` leaked as constant labels on every series. *Scope-clear; don't leak
   the tenant header as a metric label.*
8. Optimized but under-hardened (guardrails/health_check/scheduling added late). *Hardening ships day 1.*
9. An allowlist silently blinds ruler deps; **helm silently ignores unknown value keys**. *Prefer denylist;
   eyeball the rendered object / args after any chart-values change.*
10. `k8s_statefulset_name` escaped our first delete-list. *Enumerate ALL of `k8s.{daemonset,replicaset,
    statefulset}.name`; let the analyzer surface stragglers.*

---

## 12. Scale gaps to ADD at the company (we did not, in the sandbox)
- **Per-tenant Mimir limits / cardinality budgets** (`max_global_series_per_user`,
  `max_label_names_per_series`, out-of-order window) — the real backstop; collector-side trims are
  best-effort, the limit is the enforcement.
- **Cost attribution** per tenant (series × retention) → a feedback loop teams see.
- **CI gate** on template PRs: `baseline.sh` diff (a budget regression fails the PR) + `helm template` +
  `otelcol-contrib validate`.
- **Drift detection**: which of the 100 clusters run which template version.
- **Per-tenant cardinality SLO + growth alert** (alert on `cortex_ingester_memory_series` slope per
  tenant).
- cAdvisor `id`/`name`/`image` labeldrop (high churn) — needs a per-use consumption check first.

---

## Reference implementation (this sandbox — examples ONLY, not requirements)
Real numbers/paths from where this was proven, to make the abstractions concrete. **Your company repo
will differ — discover yours (KICKOFF-PROMPT Step 0).**
- Stack: Grafana OSS + Mimir/Loki/Tempo, OTel Operator + Target Allocator, EKS ap-south-2, profile
  `obsrv`, tenant `obsrv`, ingestion `otel.<domain>:443`.
- Collectors: `meta_ta` (statefulset+TA, match-all prometheusCR) `_meta_monitoring/manifests/meta_ta.yaml`;
  `meta_metrics` (daemonset, static kubelet/cadvisor) `meta_metrics.yaml`; gateway `_8_otel_collector/
  manifests/values.yaml` (`resource_to_telemetry_conversion: true`). Helm components via uniform values
  files (`ksm-values.yaml`, `node-exporter-values.yaml`). Dashboards `_9_grafana_dashboards/dashboards/
  {mimir,k8s,OtelCol}/` via the TF Grafana provider.
- Per-job results (the applied capstones): node-exporter 1906→246/target (~87%); KSM 4946→3461 (~30%);
  cAdvisor 6357→1740 (~73%); apiservers `apiserver_/etcd_` ≈56% of ingest dropped; aws-lb-controller
  978→200 (histogram whole-family); label dedup ~10 labels/series off + scope-clear.
- The hardened 4-tier skeleton lives in `_golden_template/{10-node-metrics,20-cluster-metrics,...}.yaml`
  (validated offline with `otelcol-contrib 0.152.0 validate`); the per-job tracker + method in
  `_meta_monitoring/OPTIMIZATION.md`; the verbose teaching in `learning/eod/Topic{5..13}.md`.
