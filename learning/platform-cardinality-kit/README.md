# platform-cardinality-kit

A self-contained, **repo-agnostic** kit to (A) build a hardened + low-cardinality OpenTelemetry collector
**template for new teams**, and (B) **analyze and reduce metrics cardinality on existing clusters**, on a
Grafana **LGTM** platform where per-team EKS collectors ship to a **central Mimir** (tenant per
`X-Scope-OrgID`).

Proven on a reference sandbox; **all company paths here are placeholders** — the kit discovers your real
layout when you run it.

## How to use
1. Drop this whole folder into your company repo.
2. Ensure the toolchain — see **`TOOLCHAIN.md`** (CLIs + MCPs + the skill).
3. Open Claude Code (Opus 4.7, ~1M, GitHub access) with the repo as work_dir and paste the block from
   **`KICKOFF-PROMPT.md`**. It runs **discovery-first** (learns your layout), then both tracks. It never
   applies changes — it hands you the commands.

## What's inside
| File | What it is |
|---|---|
| `README.md` | this map |
| `KNOWLEDGE.md` | **the correctness runbook** — the method + every pitfall as a guardrail + the MISTAKES LEDGER. Read first. |
| `TOOLCHAIN.md` | every CLI / MCP / skill the kit needs, with the gotchas |
| `KICKOFF-PROMPT.md` | paste-in marching orders for the company Claude Code (Step 0 = discover your repo) |
| `cardinality-reduction/SKILL.md` | the Claude Code skill: workflow + guardrails |
| `cardinality-reduction/baseline.sh` | diff-friendly Mimir snapshot (before/after). `MIMIR_TENANT=<org> ./baseline.sh out.txt` |
| `cardinality-reduction/analyze.sh` | read-only ranked cardinality report + suggested reversible drops. `MIMIR_TENANT=<org> ./analyze.sh --dashboards-dir <repo>` |
| `cardinality-reduction/references/cookbook.md` | the PromQL library + the lever→mechanism map |

## The one-paragraph method
Find the firehoses (top families by series) → **consumption-gate** against the dashboards/rules repo (at
PromQL level, not substring) → cut down the **lever ladder** (exporter-native → SM/PM `metricRelabelings`
→ cAdvisor keep-list → label dedup → churn labels), **reversible-first**, **whole-family for histograms**,
**label hygiene at the per-team collector not the shared gateway** → **validate** with `baseline.sh`
before/after (`up==0` flat, no new dup, joins resolve, `samples_ingested` down) → record the per-job
tracker + the get-it-back path. The real backstop is **per-tenant Mimir limits**.

## Scripts are read-only
`baseline.sh` and `analyze.sh` only run PromQL queries via a temporary port-forward. They change nothing.
All config edits are reviewed by a human and applied by a human (the kit never runs terraform/helm).
