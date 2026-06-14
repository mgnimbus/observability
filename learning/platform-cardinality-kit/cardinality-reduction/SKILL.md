---
name: cardinality-reduction
description: Use when assessing or reducing Prometheus/Mimir metrics cardinality on an LGTM + OpenTelemetry platform (per-team EKS collectors → central Mimir, tenant per X-Scope-OrgID). Baseline → consumption-gate against the dashboards/rules repo → tiered reversible drops → validate before/after. Covers per-job firehoses, the 3-way label dedup, the OTLP-histogram whole-family rule, spillage, and the verification gates.
---

# cardinality-reduction

Reduce metrics cardinality **safely and reversibly** on a shared-Mimir LGTM platform. The full method
and every pitfall are in **`../KNOWLEDGE.md`** — read it first. This skill is the operating procedure +
the two scripts.

## When to use
- A tenant's series count / Mimir cost is high and you need to find and cut the waste.
- Building or reviewing the new-team collector template (Track A) for cardinality + hardening.
- Any change that drops/relabels metrics or alters series identity.

## Guardrails (non-negotiable)
1. **Never run `terraform plan`/`apply` (or `helm upgrade`) yourself** — edit + validate the config, then
   hand the human the exact command. Apply mutates a live, prod-parity cluster.
2. **Consumption-gate every drop** against the dashboards/rules **repo** (not a `kubectl get cm`), at
   **PromQL level**. If something reads it, don't drop it.
3. **Two-tier, reversible-first**: prefer ServiceMonitor/PodMonitor `metricRelabelings` (tier-2, the
   component still exposes it) over exporter-native removal (tier-1, redeploy to undo). Always record the
   get-it-back path.
4. **Label hygiene at the per-team collector, never the shared gateway** (multi-tenant blast radius).
5. **Validate live** (Grafana MCP or curl) — a claim about series/jobs is backed by a query, not a guess.
   Prefer trimmed CLI (`curl|jq|head`) for token economy.

## Workflow
1. **Discover** — confirm the Mimir query gateway (svc/port/path), the tenant (`X-Scope-OrgID`), and the
   dashboards/rules **repo path**. (KICKOFF-PROMPT Step 0 does this for a whole repo.)
2. **Baseline (before)** —
   `MIMIR_TENANT=<org> ./baseline.sh baseline-before.txt`
3. **Analyze** —
   `MIMIR_TENANT=<org> ./analyze.sh --dashboards-dir <dashboards-repo> --out report.txt`
   Read the firehoses, duplicate/constant/churn labels, spillage, and the consumption cross-ref.
4. **Propose** drops down the lever ladder (KNOWLEDGE §3), consumption-gated, whole-family for histograms
   (§5), at the producer for labels (§4). Write the diffs; **hand the human the apply command**.
5. **Validate (after)** — re-`analyze`/`baseline`, `diff -u before after`; check `up==0` unchanged, no new
   dup, joins resolve, `samples_ingested` down (staleness-free), consumed families intact.
6. **Record** — update the per-job tracker (the OPTIMIZATION.md-style table) + the reversibility note.

## Files
- `baseline.sh` — diff-friendly Mimir snapshot (env-parameterized; `MIMIR_TENANT` required).
- `analyze.sh` — read-only ranked report + suggested reversible drops (`--dashboards-dir` for the gate).
- `references/cookbook.md` — the PromQL library + the lever→mechanism map.

## Read next
`../KNOWLEDGE.md` (the runbook + the MISTAKES LEDGER §11) · `../TOOLCHAIN.md` (CLIs/MCPs needed).
