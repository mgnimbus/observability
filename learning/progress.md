# Progress Tracker

Rule: a topic is **mastered** only when I pass its end-of-topic quiz *and* can sketch its
slice of the master diagram (see `CLAUDE.md`). Claude updates this after each quiz and does
not advance until the current topic is mastered.

Legend: ⬜ not started · 🟡 in progress · ✅ mastered (quiz passed) · 🔁 needs review

**Current focus:** Phase 1 · Topic 1 — *What is telemetry*
**Next up:** Topic 2 — *What is a metric*

---

## Phase 1 — Metrics
| # | Topic | Status | Quiz | Notes |
|---|-------|--------|------|-------|
| 1 | Telemetry | ⬜ | – | |
| 2 | What is a metric | ⬜ | – | |
| 3 | Metric types | ⬜ | – | |
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

## Quiz score history
_(Claude appends: date · topic · result · the gap it revealed)_
