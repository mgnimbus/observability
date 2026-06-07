# Progress Tracker

Rule: a topic is **mastered** only when I pass its end-of-topic quiz *and* can sketch its
slice of the master diagram (see `CLAUDE.md`). Claude updates this after each quiz and does
not advance until the current topic is mastered.

Legend: ⬜ not started · 🟡 in progress · ✅ mastered (quiz passed) · 🔁 needs review

**Current focus:** Phase 1 · sequential, **each topic taught at deep-dive depth inline** (user decision 2026-06-07) — the separate 10-part deep-dive is retired as a standalone track; its parts fold into the matching sequential topic. T6 Scraping taught consolidated (P4–P6 folded in); quiz parked.
**Next up:** T7 — *Exporters* (deep); then T8 — *node-exporter* (deep, = old P2).

---

## Phase 1 — Metrics
The remaining metrics topics are taught as a **10-part internals deep-dive** (user requested
2026-06-07) — one part/session, gated (interview-level Qs), grounded live, ≥1 Mermaid +
EKS/Grafana exercise each. The **Deep-dive** column tags which part(s) cover each topic.
**Updated 2026-06-07 (supersedes the standalone track):** deep-dive depth is now delivered
**inline at each sequential topic** (T7 exporters deep · T8 node-exporter = P2 · T9 KSM = P1 ·
T10/T12 = P3 · …). The Deep-dive column below still maps topic→part(s) for reference; we no longer
follow the separate P1→P10 order.
**Active order:** **P1** KSM `kube_pod_info` gen, informers/shared-cache (T9) → **P2**
node-exporter `/proc`+`/sys`, `node_cpu_seconds_total` kernel→exposition (T8) → **P3**
ServiceMonitor→Operator→generated config→reload, config-reloader sidecar (T10/T12) → **P4**
k8s SD `role: endpoints`, Discovery/Scrape/Target managers, watches/target-groups (T6) →
**P5** relabeling rule-by-rule, `exported_pod→pod`, before/after (T6/T10) → **P6** scrape
lifecycle scheduler→HTTP→parse→sample→fingerprint→series→WAL (T6) → **P7** TSDB head/chunks/
WAL/memSeries/index/compaction (T18) → **P8** remote_write QueueManager/shards/snappy/protobuf/
retry-backpressure (T19) → **P9** Mimir distributor→ingester→WAL→TSDB→S3, hashing/replication/
tenancy/query (T18/T20/T21) → **P10** end-to-end `kube_pod_info` capstone API→KSM→SD→relabel→
scrape→WAL→Mimir→S3→Grafana (T28).

| # | Topic | Status | Quiz | Deep-dive | Notes |
|---|-------|--------|------|-----------|-------|
| 1 | Telemetry | ✅ | pass | — | boundary (state≠signal) + detect/diagnose solid; node-exporter origin deferred to T8 |
| 2 | What is a metric | ✅ | pass | — | series-identity + cardinality strong; sample=(ts,value) took two nudges; spotted redundant label to drop |
| 3 | Metric types | ✅ | pass | — | mastered 2026-06-07 (re-ask): sum-by-le merges same-`le` bucket rates across sources; summary quantiles can't be merged. counter/gauge/histogram solid; grounded on live cortex histogram. see eod/Topic3.md |
| 4 | Prometheus architecture | ✅ | pass | — | mastered 2026-06-07 (live TA hands-on): 4 jobs = TA(SD)+OTel receiver(retrieval)+Mimir(TSDB/PromQL/ruler/AM); SD funnel discover→relabel→assign; per-node vs consistent-hashing; up==0 troubleshoot ladder; exported_*/honor_labels. see eod/Topic4.md |
| 5 | Pull model | ✅ | pass | — | mastered 2026-06-07 (4 live /metrics archetypes — node-exporter/KSM/Mimir/cAdvisor): pull = scraper initiates GET; collector = pull→push pivot, TA never scrapes; up = scrape-success ≠ app-health (500→up=0); counter location (kernel survives pod restart vs in-process resets that rate() heals); ephemeral→Pushgateway (stale value + breaks up); unreachable→push. see eod/Topic5.md |
| 6 | Scraping | 🟡 | – | P4·P5·P6 | taught consolidated 2026-06-07 (P4–P6 folded): SD roles; discover→relabel→assign (apiservers 306→2 via `keep`); two relabel stages (relabel_configs target-level vs metric_relabel_configs = cardinality lever); `__` label lifecycle + instance defaults to `__address__`; scrape→fingerprint→series. Quiz parked; Topic6.md pending |
| 7 | Exporters | ⬜ | – | — | |
| 8 | node-exporter | ⬜ | – | P2 | |
| 9 | kube-state-metrics | 🟡 | – | **P1** ← current | active deep-dive part |
| 10 | ServiceMonitor | ⬜ | – | P3·P5 | |
| 11 | PodMonitor | ⬜ | – | — | |
| 12 | Prometheus Operator | ⬜ | – | P3 | |
| 13 | OTel metrics | ⬜ | – | — | |
| 14 | OTel Collector | ⬜ | – | — | |
| 15 | Processors | ⬜ | – | — | |
| 16 | Receivers | ⬜ | – | — | |
| 17 | Exporters (OTel) | ⬜ | – | — | |
| 18 | Mimir architecture | ⬜ | – | P7·P9 | |
| 19 | remote_write | ⬜ | – | P8 | |
| 20 | Multi-tenancy | ⬜ | – | P9 | |
| 21 | Query path | ⬜ | – | P9 | |
| 22 | Grafana dashboards | ⬜ | – | — | |
| 23 | Recording rules | ⬜ | – | — | |
| 24 | Alerting | ⬜ | – | — | |
| 25 | Cardinality | ⬜ | – | — | |
| 26 | Cost optimization | ⬜ | – | — | |
| 27 | Scaling Mimir | ⬜ | – | — | |
| 28 | Troubleshooting missing metrics | ⬜ | – | P10 | end-to-end capstone |

## Phase 2 — Logs   ⬜ (locked until Phase 1 complete)
## Phase 3 — Traces ⬜ (locked until Phase 2 complete)
## Phase 4 — Full LGTM ⬜ (locked until Phase 3 complete)

---

## Misconceptions log (things I got wrong — revisit these)
- 2026-06-06: Believed Grafana was exposed via the public **NLB**. Reality: Grafana = its
  own internet-facing **ALB** ingress; the NLB fronts **OTel ingestion**. → revisit
  "NLB vs ALB" + the ingress/datasource path.
- 2026-06-06: Conflated the **Grafana org** `obsrv` with the **backend tenant**
  `X-Scope-OrgID: obsrv`. They're separate layers (UI-side vs Mimir/Loki/Tempo-side).
  Dropped the Grafana org for dev; backend tenant header still scopes the data. → revisit
  "Grafana org ≠ backend tenant" in the cheatsheet.
- 2026-06-06: T1/Q3 — said "Prometheus pulls metrics, then OTel Collector transforms."
  Reality: NO Prometheus *server* in this stack; the OTel Collector + Target Allocator
  does the pull-scrape (prometheus receiver via ServiceMonitor/PodMonitor CRDs) and
  remote_writes to Mimir. Self-corrected on the quiz. → confirm against config at T4/T14.
- 2026-06-07: T4 — PromQL aggregation operators (`count`, `group`) **drop `__name__`**, so
  `count without(job, otel_collector_id)(...)` is a *bad* duplication test (it counts
  metrics-per-target, not duplicate series). Use explicit `count by (<full identity>)`.
  (Full detail in `_meta_monitoring/OPTIMIZATION.md`.)
- 2026-06-07: T2/T4 brutal re-quiz — **`scrape_interval` does NOT reduce active-series count**
  (it cuts samples/sec & ingest cost). Active series = unique label-set cardinality; the lever
  is `metric_relabel_configs` keep/drop lists (P3). Also: series **identity = `__name__` +
  labels only** — value/timestamp are the *sample*, not the identity. And on first pass the
  four Prometheus jobs were given as SD/Retrieval/relabel/push/storage — the real four are
  **SD · Retrieval · TSDB · PromQL engine** (+ruler); `remote_write` is the serverless add-on,
  not one of the four. Recovered all on retry.
- 2026-06-07: T5 — read `promhttp_metric_handler_requests_total` under 4 jobs as "node-exporter
  scraped by 4 jobs." Reality: it's a `client_golang` **library** metric every Go exporter emits
  (node-exporter + 3 Loki memcached caches) — same NAME, 4 different sources; identity =
  `job`+`instance`, not the bare name. node-exporter's own `node_*` sit under one job (51 series).
  → series-identity (T2) callback.
- 2026-06-07: T5 — said `rate()` "sees no reset" for an in-process counter reset. Reality:
  `rate()`/`increase()` **detect** a reset (value drops below prior) and **compensate**; "no reset"
  applies only to kernel-sourced counters (`node_cpu_seconds_total` survives a node-exporter *pod*
  restart — only a node reboot resets). Where the counter lives decides reset behavior.
- 2026-06-07: T5 — first chose "pull" for a target you can't reach inbound. Reality: pull needs the
  scraper to open a connection *to* the target; no inbound path → **push** (target sends outbound to
  your collector). cAdvisor is the proxy escape hatch (apiserver reaches the kubelet).

## Quiz score history
_(Claude appends: date · topic · result · the gap it revealed)_
- 2026-06-06 · T1 Telemetry · PASS · solid on boundary (state≠telemetry) + detect-vs-diagnose; gaps: omitted node-exporter as emitter and explicit pull/push labels on Q3 (carry to T8/T19).
- 2026-06-06 · T2 What is a metric · PASS · series-identity + cardinality cold; repeatedly omitted timestamp until pushed (sample=(ts,value)); correctly picked pod_uid as cardinality risk + service_instance_id as droppable-redundant.
- 2026-06-07 · T3 Metric types · PASS · `sum by (le)` = combine same-boundary bucket rates across sources; summary not mergeable (quantiles don't average, no `le` series). Compact but correct on both halves. Grounded on live cortex_request_duration_seconds (p50~22ms, push p99~66ms/5m, ~209k active series). Added depth: rate-per-bucket-before-sum, +Inf==_count.
- 2026-06-07 · T4 Prometheus architecture · PASS · Q3 clean (ephemeral / no-HA / no-multi-tenancy + `remote_write`); Q1 demonstrated live (4 jobs → TA/OTel-receiver/Mimir) by exploring both Target Allocators' HTTP APIs; Q2 gap = ② `up==0` (the Retrieval rung) — closed when the learner asked *what generates `up`*. Grounded live: SD funnel (302→2, 138→0), per-node vs consistent-hashing, 51 up/2 down apiservers, 41+12=53. see eod/Topic4.md.
- 2026-06-07 · T1–T4 brutal re-quiz (12-Q exam, user asked for exam-grade) · PASS w/ review flags · Clean cold: sample=(ts,value), aggregatable types, histogram-vs-summary mergeability, `+Inf`==`_count` + `sum by(le)(rate)`→`histogram_quantile`, `up` generation + 4-checkpoint ladder. **Recovered on retry:** the four jobs (had dropped PromQL), `honor_labels` vs `exported_*` (first pass blank), `otel_collector_id` label-flip danger (ties to today's Wave 4 KSM move). **Still soft (revisit):** precise definition of "active series" (= series with a fresh sample in the head/staleness window), and series-vs-sample wording. Misconceptions logged above.
- 2026-06-07 · T5 Pull model · PASS · clean on up-semantics (scrape-success ≠ app-health; 500→up=0),
  the pull→push boundary (collector pivot, TA never scrapes), Pushgateway downsides (stale value +
  loss of liveness), and reachability→push. Closed in-quiz: rate() reset handling (in-process cortex
  reset → rate() *compensates*; node_cpu kernel-sourced → no reset) and reachability (first said
  "pull" for an unreachable target → corrected to push). Grounded live on 4 /metrics archetypes —
  node-exporter 1673 series (scrape 1673 samples/29ms), KSM 6141, Mimir ingester 1300
  (cortex_ingester_memory_series=64093), cAdvisor 5550 via apiserver proxy. see eod/Topic5.md.
