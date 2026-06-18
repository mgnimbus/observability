# Progress Tracker

Rule: a topic is **mastered** only when I pass its end-of-topic quiz *and* can sketch its
slice of the master diagram (see `CLAUDE.md`). Claude updates this after each quiz and does
not advance until the current topic is mastered.

Legend: ⬜ not started · 🟡 in progress · ✅ mastered (quiz passed) · 🔁 needs review

**Current focus:** Phase 1, deep-dive depth inline. **T7 Exporters, T8 node-exporter, T9 KSM all MASTERED 2026-06-14**, each with a live **cleanup capstone** (per-job cardinality optimization on the meta-monitoring stack — tracked in `_meta_monitoring/OPTIMIZATION.md`). **T10 cAdvisor (+kubelet) MASTERED 2026-06-14** (quiz passed; Q4 join deferred — see below); cleanup DONE (container_ firehose −73%, cluster ingest −9.3k). **T11 ServiceMonitor + T12 PodMonitor + T13 Prometheus Operator MASTERED 2026-06-14** (T12: live-verify caught two stale claims of mine — TA `podMonitorSelector` is already `{}` **and** the PodMonitor CRD **is installed**, both gates open, 0 objects by design. T13: closed the Operator-vs-Prometheus-server conflation; grounded on the live no-Operator/no-server disaggregation). Cumulative sweep so far: cluster `samples_ingested` **52,775 → 37,315 (~29%)**.
**Next up (RESUME HERE):** ▶ **T14 final exam** — 5 brutal Qs sit unanswered at the bottom of
`eod/Topic14.md`; answer cold + grade to **lock T14**, then advance to **T15 OTel Collector**. T14
*core* mastered 2026-06-18 (temporality · data model · instruments · exemplars · native histograms);
gold doc + 3 diagrams written; grounded in live gateway PRW flags.

**Session 2026-06-14 close-out (what's DONE, so we don't redo):**
- **T11 infra-controller cleanup — DONE.** aws-lb-controller SM `metricRelabelings` whole-family
  histogram drop (`_(bucket|sum|count)`) → **978→200 series** (cert-manager left alone — 76 series, all
  high-value `certmanager_*`). Applied + validated.
- **3-way label dedup — DONE (the big one), at the PER-TEAM collectors (NOT the gateway).** `resource`
  delete of the duplicate `k8s_*`/`server_*`/`url_scheme` resource attrs + `transform` scope-clear
  (`otel_scope_*`) in `meta_ta`+`meta_metrics`; node-exporter `node` relabel restored; KSM `uid`
  labeldrop. Applied + validated (k8s_* gone from node_cpu; gateway untouched → other tenants safe).
- **Platform-as-a-Product kit — BUILT** at `learning/platform-cardinality-kit/` (KNOWLEDGE runbook +
  mistakes-ledger, `cardinality-reduction` skill w/ baseline.sh+analyze.sh+cookbook, TOOLCHAIN,
  KICKOFF-PROMPT). Scripts smoke-tested read-only. Staged for the user's commit. (Ultraplan merge dropped.)

**Open cardinality follow-ups (deferred, NOT blocking T14):**
- Next firehoses = the LGTM components' OWN histograms (`loki_*`/`cortex_*`/`grafana_*` `_bucket`) —
  surfaced by analyze.sh; tackle in the Loki/Mimir/Grafana topics (T18/T22) or a dedicated sweep.
- `k8s_statefulset_name` escaped the dedup delete-list (add it). cAdvisor `id/name/image` labeldrop
  (needs per-use check). The 5 golden hardening items for the meta collectors (guardrails/health_check/
  nodeSelector/priorityClass/updateStrategy/min2). Update `OPTIMIZATION.md` tracker with the dedup rows.

**Deferred chapter — "PromQL & metric joins"** (`group_left`, owner-chain, cАdvisor×KSM rollup — T10 Q4);
slot around the query-path/Grafana topics. (Numbering: cAdvisor=T10, SM=T11, PodMonitor=T12, PromOp=T13,
OTel metrics=T14, rest +1.)

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
| 12 | PodMonitor | ✅ | pass | — | **MASTERED 2026-06-14.** SM minus the Service: `role: pod` (vs `endpoints`), selects **pods** by label, port = **container** port name (`portNumber` for unnamed), only `__meta_kubernetes_pod_*` survives (endpoints/service families vanish). **Separate CRD** (absent → apply rejected at admission) — but **installed in our cluster** (live-verified, ships each daily deploy); `podMonitorSelector` nil=none/`{}`=all (ours is `{}`, `meta_ta.yaml:23`). **Both gates open** → we run **0 PodMonitor *objects* by design** (mint a Service → SM-only, one discovery plane). Not-ready CrashLoop pod IS a target under both SM+PM (`up=0`); failing-to-start = KSM's job. see eod/Topic12.md. (was T11) |
| 13 | Prometheus Operator | ✅ | pass | P3 | **MASTERED 2026-06-14.** Controller, **NOT** a server/scraper/TSDB — input=CRDs, output=`prometheus.yaml` Secret + managed Prometheus StatefulSet (touches 0 samples). **CRD ≠ controller** (inert objects until a consumer reads them → why we have SM/PM CRDs with no Operator). Reconcile/reload = regenerate Secret → **config-reloader sidecar** `/-/reload`; our analog = **TA-served HTTP target list** + **collector receiver polling the TA**. Live: **no Operator, no Prometheus server**; OTel Operator runs; only a **3-CRD subset** (servicemonitors/podmonitors/scrapeconfigs). Disaggregation: Operator→OTel Operator, config-gen+SD→TA, scrape→collector, TSDB/PromQL/ruler→Mimir, PrometheusRule→Mimir ruler. see eod/Topic13.md. (was T12) |
| 14 | OTel metrics | 🟡 | core | — | **CORE MASTERED 2026-06-18; 5-Q final exam PENDING (resume).** Two dialects (prometheus receiver pull / otlp receiver push) → one cumulative PRW egress, diverge only at the receiver. **Temporality:** PRW **DROPS** delta monotonic sums → symptom = *missing metric* (not inflated `rate()`); SDK OTLP default = cumulative; `deltatocumulative` is stateful (`max_stale` 5m / `max_streams` cap → OOM). **Translation:** sanitize `.`→`_` + `add_metric_suffixes` (`_total`/units; rebuilds histogram family); `service.name`→`job`, `service.instance.id`→`instance`; resource attrs → `target_info` **by default** vs **our** `resource_to_telemetry_conversion:true` flatten (+`target_info.enabled:false`). **Instruments:** UpDownCounter→gauge (lossy), Observable*=callback flavor (not a type), **no OTel summary**. **Exemplars** (RW v2 + Mimir `max_global_exemplars_per_user`, both gates shut). **Native vs classic histograms** (Mimir `native_histograms_ingestion_enabled` OFF). see eod/Topic14.md |
| 15 | OTel Collector | ⬜ | – | — | |
| 16 | Processors | ⬜ | – | — | |
| 17 | Receivers | ⬜ | – | — | |
| 18 | Exporters (OTel) | ⬜ | – | — | |
| 19 | Mimir architecture | ⬜ | – | P7·P9 | |
| 20 | remote_write | ⬜ | – | P8 | |
| 21 | Multi-tenancy | ⬜ | – | P9 | |
| 22 | Query path | ⬜ | – | P9 | |
| 23 | Grafana dashboards | ⬜ | – | — | |
| 24 | Recording rules | ⬜ | – | — | |
| 25 | Alerting | ⬜ | – | — | |
| 26 | Cardinality | ⬜ | – | — | |
| 27 | Cost optimization | ⬜ | – | — | |
| 28 | Scaling Mimir | ⬜ | – | — | |
| 29 | Troubleshooting missing metrics | ⬜ | – | P10 | end-to-end capstone |

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
- 2026-06-14: T12 — **conflated the two selector layers.** Asked "if `serviceMonitorSelector: {}`
  selects all, why is the TA only scraping KSM/Mimir/etc.?" Reality: `{}` selects all **ServiceMonitor
  *objects*** (opt-in intent CRDs — 23 exist), **not** all Services; each SM then has its **own narrow
  `selector`** picking specific Services. Two layers: TA→intent (`serviceMonitorSelector`) vs
  SM→targets (the SM's own `selector`). What's scraped = union of all SMs' target selectors = "the
  SM-enabled objects." Also Q1: twice missed `podMonitorSelector` as the 2nd discovery blocker
  (conflated with Q3's `__meta_*` source-labels); recalled `{}` on the 3rd nudge. And Q5 factual slip:
  said a CrashLooping pod has "no IP" — it **has** an IP (scrapeable as a not-ready endpoint, `up=0`);
  the no-IP case is `Pending`/`ImagePullBackOff`. **Mentor self-corrections (×2, learner caught both):**
  (i) I said the TA's `podMonitorSelector` is nil (stale `OPTIMIZATION.md`) — it's explicitly `{}`;
  (ii) I said the PodMonitor CRD is absent ("apply rejected") — it's **installed** (live-verified; my
  `kubectl get podmonitor -A 2>/dev/null` had hidden the absent-vs-0-objects distinction). True state:
  both gates open, 0 PodMonitor objects by design. → **verify-live (`kubectl get crd`/`api-resources`,
  no stderr suppression) before asserting CRD/selector cluster state.**
- 2026-06-14: T13 — **conflated the Prometheus Operator with the Prometheus server** (assessment: said
  the Operator "does SD → scrape → storage"). Reality: the Operator is a **controller** that writes
  `prometheus.yaml` (a Secret) + manages the Prometheus StatefulSet — it **touches no samples**;
  scraping = the server's SD/retrieval, storage = the server's TSDB. Closed by quiz time. Also (Q3)
  first gave the SD/scrape split instead of the **artifact (`prometheus.yaml` Secret) + reload trigger
  (config-reloader sidecar `/-/reload`)** and their TA-stack analogs (TA-served HTTP target list +
  collector receiver polling); and (Q4) said "TA down → list empty" — corrected to "keeps the **last
  fetched** target list," parallel to Operator-down. Recovered all on retry.
- 2026-06-18: T14 — initially modeled the delta-temporality failure as an **inflated `rate()` graph**
  (true *conceptually*). In our **actual** pipeline the `prometheusremotewrite` exporter's contract is
  cumulative and it **DROPS** delta monotonic sums ("cumulative or otherwise dropped") — so the real
  symptom is a **MISSING metric** (silent), debugged via T29, not a wrong graph. Also at assessment:
  stated "all resource attributes become labels" as a universal rule — that's **our** config
  (`resource_to_telemetry_conversion: true`), NOT the default (default parks them in `target_info`,
  keyed by `job`+`instance`, joined via `group_left`; `service.name`→`job`, `service.instance.id`→
  `instance`). And mapped OTel **async/observable → Summary** (wrong twice: observable is the
  *callback flavor* of the same instruments — `ObservableCounter`→counter — and **OTel emits no
  summaries** at all). All corrected in-topic; grounded on live gateway PRW flags.

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
- 2026-06-14 · T8 node-exporter · PASS · host/`/proc`+`/sys` read-on-scrape, DaemonSet blast-radius
  1-node, counters kernel-resident (`node_boot_time_seconds` = pod-restart vs node-reboot tell), inner
  liveness `node_scrape_collector_success`. Cleanup capstone applied: default-deny allowlist +
  collector/fs/netdev trims → **1906→246 samples/target (~87%)**. see eod/Topic8.md.
- 2026-06-14 · T9 kube-state-metrics · PASS · client-go informers (LIST→WATCH→cache; 0 API calls per
  scrape), info-metric join `* on(ns,pod) group_left(node) kube_pod_info` (subject vs `k8s_*` labels),
  enum-expansion cardinality, `--metric-labels-allowlist` footgun. Two-tier cleanup → **4946→3461/target
  (~30%)**. see eod/Topic9.md.
- 2026-06-14 · T10 cAdvisor (+kubelet) · PASS (Q4 join deferred to the "PromQL & joins" chapter) ·
  embedded in kubelet, cgroups→`container_*`, scraped `:10250/metrics/cadvisor` by the daemonset, #1
  firehose+churn (`id`/`container_id`/`image_id`), only lever = `metric_relabel_configs` keep-list (no
  native knob). Cleanup → **cadvisor 6357→1740/target (~73%)**. see eod/Topic10.md.
- 2026-06-14 · T11 ServiceMonitor · PASS · CRD = scrape *intent*, not a scraper; consumed by the TA;
  selects Services→Endpoints (per-pod, not VIP); `relabelings`=Stage1 / `metricRelabelings`=Stage2;
  #1 fail = 0 targets. **Corrected on retry:** Q3 two-stage relabel conflation (again — see T6) and
  Q4 (claimed VIP churns on pod restart — VIP is stable, load-balances to one random backing pod).
  Cleanup capstone (infra-controller SM sweep) pending @keyboard. see eod/Topic11.md.
- 2026-06-14 · T12 PodMonitor · PASS · clean cold on port-name semantics (+`portNumber`), the
  meta-label split (`role: pod` drops endpoints/service families), the mint-a-Service principle + its
  cost, and KSM-not-scrape for failing-to-start pods. **Recall snags (not concept):** Q1's 2nd blocker
  (`podMonitorSelector` nil-vs-`{}`, conflated with Q3 meta-labels) and a Q5 factual slip (CrashLoop
  "no IP" → it has one). Live-verify corrected **two** stale claims of mine: TA is already `{}`, and
  the PodMonitor CRD **is installed** (not absent) — both gates open, 0 objects by design. Also closed
  the `serviceMonitorSelector: {}` = "all SM *objects*, not all Services" two-layer-selector confusion.
  see eod/Topic12.md.
- 2026-06-14 · T13 Prometheus Operator · PASS · opened with the **Operator-vs-server conflation**
  ("Operator does SD/scrape/storage") — fully corrected. **Recovered on retry:** Q3 (artifact =
  `prometheus.yaml` Secret + reload = config-reloader sidecar `/-/reload`; analogs = TA HTTP target
  list + collector receiver poll), Q4 TA-down half ("list empty" → keeps last fetched list, parallel
  to Operator-down), Q5 second scale reason (Mimir S3/long-retention/multi-tenant/HA). Clean cold by
  quiz on Q1 (Operator = controller, not server) + Q2 (CRD ≠ controller; inert objects). Grounded on
  live disaggregation: no Operator, no Prometheus server, OTel Operator running, 3-CRD subset only.
  see eod/Topic13.md.
- 2026-06-18 · T14 OTel metrics · **CORE PASS (5-Q final exam PENDING — resume)** · clean on receiver
  divergence (pull vs push, merge only past the receiver), temporality (delta vs cumulative + the
  `rate()` reset-inflation mechanism applied from T5), the 3-layer attribute model → `target_info`
  default vs our flatten + the PromQL filter contrast (vanilla needs `group_left`, ours is a direct
  label), and instrument mapping (UpDownCounter→gauge lossy; Observable=callback; **no OTel summary**).
  Depth folded in: exemplars (RW v2 + `max_global_exemplars_per_user`, both gates currently shut),
  native vs classic histograms (Mimir `native_histograms_ingestion_enabled` OFF; ~15 series→1), delta
  audit (**static** — no live cluster: no `deltatocumulative` anywhere + SDK default cumulative ⇒ apps
  cumulative). **Correction logged:** delta→PRW = **dropped/missing**, not inflated. Also amended
  `Topic3.md` with a "PromQL by type" worked-examples section (counter `rate`/`increase` vs gauge
  `avg`/`delta`/`deriv`; the reset-contract split). Grounded in live gateway PRW flags
  (`_8_otel_collector/manifests/values.yaml:90`). see eod/Topic14.md.
