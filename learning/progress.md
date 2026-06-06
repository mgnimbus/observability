# Progress Tracker

Rule: a topic is **mastered** only when I pass its end-of-topic quiz *and* can sketch its
slice of the master diagram (see `CLAUDE.md`). Claude updates this after each quiz and does
not advance until the current topic is mastered.

Legend: ⬜ not started · 🟡 in progress · ✅ mastered (quiz passed) · 🔁 needs review

**Current focus:** Phase 1 · Topic 3 — *Metric types*
**Next up:** Topic 4 — *Prometheus architecture*

---

## Phase 1 — Metrics
| # | Topic | Status | Quiz | Notes |
|---|-------|--------|------|-------|
| 1 | Telemetry | ✅ | pass | boundary (state≠signal) + detect/diagnose solid; node-exporter origin deferred to T8 |
| 2 | What is a metric | ✅ | pass | series-identity + cardinality strong; sample=(ts,value) took two nudges; spotted redundant label to drop |
| 3 | Metric types | 🟡 | – | ▶ RESUME HERE — assessment posed (3 Qs), not yet answered; see learning/eod/2026-06-06.md |
| 4 | Prometheus architecture | ⬜ | – | |
| 5 | Pull model | ⬜ | – | |
| 6 | Scraping | ⬜ | – | |
| 7 | Exporters | ⬜ | – | |
| 8 | node-exporter | ⬜ | – | |
| 9 | kube-state-metrics | ⬜ | – | |
| 10 | ServiceMonitor | ⬜ | – | |
| 11 | PodMonitor | ⬜ | – | |
| 12 | Prometheus Operator | ⬜ | – | |
| 13 | OTel metrics | ⬜ | – | |
| 14 | OTel Collector | ⬜ | – | |
| 15 | Processors | ⬜ | – | |
| 16 | Receivers | ⬜ | – | |
| 17 | Exporters (OTel) | ⬜ | – | |
| 18 | Mimir architecture | ⬜ | – | |
| 19 | remote_write | ⬜ | – | |
| 20 | Multi-tenancy | ⬜ | – | |
| 21 | Query path | ⬜ | – | |
| 22 | Grafana dashboards | ⬜ | – | |
| 23 | Recording rules | ⬜ | – | |
| 24 | Alerting | ⬜ | – | |
| 25 | Cardinality | ⬜ | – | |
| 26 | Cost optimization | ⬜ | – | |
| 27 | Scaling Mimir | ⬜ | – | |
| 28 | Troubleshooting missing metrics | ⬜ | – | |

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

## Quiz score history
_(Claude appends: date · topic · result · the gap it revealed)_
- 2026-06-06 · T1 Telemetry · PASS · solid on boundary (state≠telemetry) + detect-vs-diagnose; gaps: omitted node-exporter as emitter and explicit pull/push labels on Q3 (carry to T8/T19).
- 2026-06-06 · T2 What is a metric · PASS · series-identity + cardinality cold; repeatedly omitted timestamp until pushed (sample=(ts,value)); correctly picked pod_uid as cardinality risk + service_instance_id as droppable-redundant.
