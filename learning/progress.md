# Progress Tracker

Rule: a topic is **mastered** only when I pass its end-of-topic quiz *and* can sketch its
slice of the master diagram (see `CLAUDE.md`). Claude updates this after each quiz and does
not advance until the current topic is mastered.

Legend: ⬜ not started · 🟡 in progress · ✅ mastered (quiz passed) · 🔁 needs review

**Current focus:** Phase 1, deep-dive depth inline. **T7 Exporters, T8 node-exporter, T9 KSM all MASTERED 2026-06-14**, each with a live **cleanup capstone** (per-job cardinality optimization on the meta-monitoring stack — tracked in `_meta_monitoring/OPTIMIZATION.md`). **T10 cAdvisor (+kubelet) MASTERED 2026-06-14** (quiz passed; Q4 join deferred — see below); cleanup DONE (container_ firehose −73%, cluster ingest −9.3k). Cumulative sweep so far: cluster `samples_ingested` **52,775 → 37,315 (~29%)**.
**Next up:** **T11 infra-controller cleanup sweep** (cert-manager/aws-lb-controller/webhook/cainjector SM `metricRelabelings`) — needs keyboard/apply; then **T12 PodMonitor**. **NEW deferred chapter — "PromQL & metric joins"** (`group_left`, owner-chain, the cАdvisor×KSM rollup — T10 Q4 deferred here by user request); slot it around the query-path/Grafana topics. (cAdvisor inserted as **T10** → ServiceMonitor=T11, PodMonitor=T12, Prometheus Operator=T13, rest +1.)

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
| 6 | Scraping | ✅ | pass | P4·P5·P6 | mastered 2026-06-13 (parked quiz completed): SD roles; discover→relabel→assign (apiservers 306→2 via `keep`); two relabel stages (relabel_configs target-level vs metric_relabel_configs = cardinality lever); `__` label lifecycle + instance defaults to `__address__`; scrape→fingerprint→series. Quiz gap = two-stage relabel conflation (Stage 1 used for both Q2+Q5), corrected. see eod/Topic6.md |
| 7 | Exporters | ✅ | pass | — | mastered 2026-06-13: exporter = **translator** for a subject that can't speak Prometheus; line vs native = **subject identity** (process itself → native; something else → exporter); **topology mirrors subject scope** (host-local→DaemonSet, cluster-global→single Deployment, one-instance→sidecar); **split liveness** (`up`=exporter vs `pg_up`/`probe_success`=subject), stale cache, SPOF-for-subject, `honor_labels`. **+KSM/sharding deep-dive added post-quiz** (learner caught the gap): KSM = stateless mirror of API state; replication ≠ HA (0 gain + dup); sharding (`--total-shards`/`--shard`, hash(uid) mod N, StatefulSet) = SCALE only. 6 Qs + answer key in eod/Topic7.md. |
| 8 | node-exporter | ✅ | pass | P2 | **MASTERED 2026-06-14; cleanup −87% (1906→246/target).** Host/OS exporter: `/proc`+`/sys` read-on-scrape → `:9100`; DaemonSet (1/node, blast radius 1 node); counters in kernel (`node_boot_time_seconds` distinguishes pod-restart vs node-reboot); host mounts + `--path.*`; inner liveness `node_scrape_collector_success`; default-deny allowlist + collector/fs/netdev trims. see eod/Topic8.md |
| 9 | kube-state-metrics | ✅ | pass | P1 | **MASTERED 2026-06-14; cleanup −30% (4946→3461/target).** client-go **informers** (LIST→WATCH→cache; scrape renders from cache, 0 API calls); **info-metric join** `* on(ns,pod) group_left(node) kube_pod_info` (subject vs k8s_* labels); enum-expansion cardinality (pods×phases); `--metric-labels-allowlist` footgun; two-tier cleanup (`--resources`/`--metric-denylist` + SM relabel). see eod/Topic9.md |
| 10 | **cAdvisor (+kubelet)** | ✅ | pass | — | **MASTERED 2026-06-14; cleanup −73% (cadvisor 6357→1740/target).** Embedded in kubelet; cgroups→`container_*`; scraped `:10250/metrics/cadvisor` by the daemonset; #1 firehose + churn; join to KSM for node/workload rollup; **only lever = `metric_relabel_configs` keep-list** (no native knob). **Quiz: 4 Qs + answer key in eod/Topic10.md.** |
| 11 | ServiceMonitor | ✅ | pass | P3·P5 | **MASTERED 2026-06-14** (Q3 two-stage relabel + Q4 VIP-load-balance corrected on retry); cleanup capstone (infra-controller SM sweep) pending @keyboard. CRD declaring scrape intent — NOT a scraper; consumed by the TA (vs classic Prometheus Operator); selects Services→Endpoints (per-pod, not VIP); `relabelings`=Stage1 (targets) / `metricRelabelings`=Stage2 (cardinality lever); #1 fail = 0 targets (selector/port-name/namespaceSelector). Infra-controller cleanup sweep lands here. (was T10; +1 after cAdvisor) |
| 12 | PodMonitor | ⬜ | – | — | (was T11) · infra-controller sweep slated here |
| 13 | Prometheus Operator | ⬜ | – | P3 | (was T12) |
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
- 2026-06-13: T6 — **conflated the two relabel stages**: named Stage 1 (`relabel_configs`) for both
  "what makes a job vanish from `/jobs`" (correct — `keep` matches 0 targets) *and* "what cuts active
  series" (wrong — that's Stage 2 `metric_relabel_configs`, per-sample/post-scrape, the cardinality
  lever). Fix: **Stage 1 = which TARGETS** (target-level, pre-scrape); **Stage 2 = which SERIES**
  (per-sample, post-scrape). Also first read the apiserver job's 306 discovered as "the apiserver's
  endpoints" — it's *every* Service's endpoints cluster-wide; the `keep` narrows to 2. And Q3a: a
  relabel **sets `instance` to the node name**, overriding the `instance=__address__` default — not
  the other way round. Recovered all on retry.
- 2026-06-13: T7 — **conflated KSM *sharding* (a SCALE tool) with *replication-for-HA*** — proposed
  "2 replicas + shard config" / "`--total-shards`/`--shard`" three times as the HA fix. Reality:
  sharding *partitions* coverage (each pod owns `hash(uid) mod N` slice, disjoint) → scales by object
  count; it does **not** give HA (a dead shard's slice goes blind). The HA answer is that KSM is
  **stateless** (rebuilds its watch cache from the API server in seconds) so replicas buy **zero**
  availability *and* duplicate every series → run **1 replica**, alert on `up==0`. Also named
  **`scrape_duration_seconds`** before correcting to **`pg_up`** as the subject-reachability gauge
  (scrape duration = how long the scrape took, not whether the exporter reached its subject).
  Recovered all on retry. → the missing teaching (KSM role + sharding) was added to `Topic7.md`.

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
- 2026-06-13 · T6 Scraping · PASS · (parked 2026-06-07, completed today). Clean cold: Q4 series
  identity = fingerprint(`__name__`+labels) → add label = new series; Q3b `__meta_*` dropped unless
  copied; Q5 stage = Stage-1 `keep` matched 0 → job absent from `/jobs`. **Corrected on retry:** the
  two-stage relabel conflation (named Stage 1 for both Q2 active-series-lever and Q5 — Q2 is Stage 2
  `metric_relabel_configs`); the 306 = all cluster endpoints not just the apiserver's; Q3a the
  relabel *sets* `instance`=node-name overriding the `=__address__` default. Q1 keep mapping nailed:
  `namespace=default ; service_name=kubernetes ; endpoint_port_name=https`. see eod/Topic6.md.
- 2026-06-13 · T7 Exporters · PASS · clean cold on Q1 subject-identity (cAdvisor=exporter,
  Grafana=native) and Q4 topology/blast-radius (per-node DaemonSet 1-node vs cluster-global KSM SPOF).
  **Corrected on retry (3 passes):** KSM *sharding (scale)* vs *replication-for-HA* — kept proposing
  shards as the HA fix; closed only after I taught KSM's role (stateless mirror) + sharding mechanics,
  landing "3 replicas buy zero availability because KSM persists nothing & rebuilds from the API
  server; run 1 replica." Also `scrape_duration_seconds`→`pg_up` correction on Q3. Caught a real
  teaching gap ("you quizzed me on sharding without teaching it") → KSM/sharding deep-dive + Q5–Q6
  added to eod/Topic7.md. see eod/Topic7.md.
