# Component Cheat-Sheet — 2-line refresher

Format per entry: **what it does** / **what to watch (the gotcha that bites you)**.
Read top-to-bottom = the telemetry journey in order.

> Session recaps live in `learning/eod/`; diagram sources in `learning/diagrams/` (Mermaid).
> Refresh this sheet whenever a new component/concept is covered.

## Origin & collection (metrics)
- **Telemetry** — The signals a system emits about itself: metrics, logs, traces (+ profiles). / It's data you *design in*, not free; every signal has a cost and a cardinality bill.
- **Metric** — A numeric measurement sampled over time, identified by a name + label set. / The label set *is* the identity — one new label value = one new time series.
- **Metric types** — counter (monotonic up), gauge (up/down), histogram (bucketed), summary (client quantiles). / Use `rate()` on counters, never on gauges; histograms explode cardinality via buckets.
- **Exporter** — A process that translates some system's state into Prometheus-format metrics on `/metrics`. / It only *exposes*; something still has to scrape it. No scrape = no data.
- **node-exporter** — DaemonSet exposing host/kernel metrics (CPU, mem, disk, net, filesystem). / Runs per-node; needs host mounts. Missing a node = blind spot, not an error.
- **kube-state-metrics (KSM)** — Single Deployment that turns the K8s API object state into metrics (deploy replicas, pod phase, restarts). / It reports *desired/observed state*, not resource usage — that's node-exporter/cAdvisor. One replica = SPOF for that data.
- **Pull / scrape model** — Prometheus periodically GETs `/metrics` from discovered targets. / Scrape interval + target count drive load; a slow target causes gaps, not retries.

## Kubernetes-native discovery (Prometheus Operator)
- **Prometheus Operator** — Controller that turns CRDs (Prometheus, ServiceMonitor, PodMonitor, PrometheusRule) into running Prometheus config. / You stop editing prometheus.yml; you create CRDs. Wrong label selectors = silently no targets.
- **ServiceMonitor** — CRD that says "scrape the endpoints behind these Services." / Selector must match the Service's labels *and* the named port; mismatch = empty target list.
- **PodMonitor** — Like ServiceMonitor but targets Pods directly (no Service needed). / Use when there's no Service; you lose Service-level labels in return.

## OpenTelemetry
- **OTel Collector** — Vendor-neutral pipeline that receives, processes, and exports telemetry (all 3 signals). / Two roles: *agent* (DaemonSet, per-node) and *gateway* (Deployment, central). Memory blowups come from missing `memory_limiter`.
- **Receivers** — Pipeline entry: OTLP, prometheus, hostmetrics, filelog, etc. / OTLP gRPC=4317, HTTP=4318. A receiver you didn't enable = silently dropped data.
- **Processors** — In-flight transform/enrich/protect: `batch`, `memory_limiter`, `k8sattributes`, `resource`, `tail_sampling`. / Order matters; `memory_limiter` first, `batch` last. `k8sattributes` is how spans/logs get pod/namespace labels.
- **Exporters** — Pipeline exit: `prometheusremotewrite`→Mimir, `loki`/`otlphttp`→Loki, `otlp`→Tempo. / Each needs the right endpoint + tenant header; a wrong `X-Scope-OrgID` lands data in the wrong tenant (or 401s).
- **remote_write** — Push protocol for shipping metric samples to a remote store (Mimir). / Backpressure + WAL: if the remote is slow, queues fill and you drop or lag. Watch `prometheus_remote_storage_*`.

## Backends (the LGTM stores)
- **Mimir** — Horizontally scalable, multi-tenant, long-term Prometheus storage on object storage (S3). / Path: distributor → ingester (in-mem + WAL) → S3 blocks → store-gateway/querier on read. Ingester memory + replication factor decide durability.
- **Loki** — Log store that indexes **labels only**, stores raw log lines as compressed chunks. / Labels are the index — high-cardinality labels (pod, trace_id) kill it. Filter with LogQL on content, label on metadata.
- **Promtail** — Loki's agent: tails files, adds labels, pushes to Loki. / Being deprecated in favor of Alloy. Label explosion starts here, not in Loki.
- **Grafana Alloy** — Successor agent (OTel-based) for metrics+logs+traces, replaces Promtail/Grafana Agent. / Config is "river"/components, not promtail YAML — different mental model.
- **Tempo** — Trace store; cheap because it indexes **only trace ID** (find-by-id), backed by S3. / Discovery comes from TraceQL + metrics-generator (service graph / span metrics), not a full index. No exemplars/links = you can't jump from a metric to a trace.

## Query, visualize, govern
- **Grafana** — Query + dashboard + alert UI over Mimir/Loki/Tempo datasources. / Datasource URLs are in-cluster service DNS; multi-tenant needs the `X-Scope-OrgID` header per datasource.
- **Grafana MCP (`mcp-grafana`)** — MCP server exposing Grafana + its datasources (Loki/Mimir/Tempo), dashboards, alerting, incidents to an AI agent as ~52 callable tools. / In-cluster (ns `grafana`, ClusterIP :8000, **SSE** transport at `/sse`); reach it with `kubectl -n grafana port-forward svc/grafana-mcp 8000:8000`. No API key baked in → auth is per-request: pass Grafana creds as an `Authorization: Basic base64(admin:pass)` header it forwards, stored static in the Claude Code MCP config. (A `${GRAFANA_MCP_AUTH}` env-var header is cleaner but only resolves for interactive sessions — background/daemon-spawned Claude sessions don't inherit sourced shell vars and 401, so we use the static token.) Admin creds = full write (create folders/annotations/incidents, manage alert rules), so blast radius is real.
- **Recording rules** — Precompute expensive PromQL into new series on a schedule. / They trade storage for query speed; a bad rule multiplies cardinality permanently.
- **Alerting** — Rules evaluate queries and fire to a receiver (Alertmanager/contact point). / Alert on symptoms (SLOs), not causes; `for:` duration prevents flapping.
- **Cardinality** — Total count of unique time series (name × every label combo). / The #1 cost and OOM driver across all three signals. One unbounded label (user_id, trace_id, URL) = outage.
- **Multi-tenancy (`X-Scope-OrgID`)** — HTTP header that isolates tenants in Mimir/Loki/Tempo. / Missing header = default/anonymous tenant; data "disappears" because you're querying the wrong tenant.
- **Grafana org ≠ backend tenant** — A *Grafana organization* isolates users/dashboards/datasources **inside the Grafana UI**; the `X-Scope-OrgID` tenant isolates data **inside Mimir/Loki/Tempo**. Two unrelated layers. / Easy to conflate (both can be named "obsrv"). Helm file-provisioning can target an existing `orgId` but **cannot create a Grafana org** — that needs the API/Terraform provider. For single-tenant setups, skip the Grafana org and rely on the backend tenant header alone.

## Networking tie-ins (why telemetry breaks at L3/L4/DNS)
- **VPC CNI** — Assigns real VPC IPs to pods on EKS. / IP exhaustion per ENI/subnet = pods stuck `ContainerCreating`; a top "metrics suddenly missing" root cause.
- **kube-proxy** — Programs iptables/IPVS so ClusterIP Services route to pod endpoints. / Stale rules / endpoint churn = intermittent datasource timeouts in Grafana.
- **CoreDNS** — In-cluster DNS resolving `svc.namespace.svc.cluster.local`. / Throttling/NXDOMAIN here looks like "Mimir/Loki datasource down" — check DNS before blaming the backend.
- **NLB vs ALB** — NLB = L4 (TCP/gRPC, fast, client-IP preserving); ALB = L7 (HTTP routing, TLS, WAF, auth). / Ingestion (OTLP gRPC) wants NLB; human UIs (Grafana) want ALB. Mixing them up is a classic mistake — I made it.

## Debugging order (from repo CLAUDE.md — memorize)
OTel collector logs → then Loki/Tempo/Mimir. EKS networking: VPC CNI → kube-proxy →
CoreDNS. Ingestion latency: Mimir distributor metrics → ingester.
