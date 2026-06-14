# KICKOFF-PROMPT.md — paste this into the company Claude Code (repo open as work_dir)

> Copy everything in the fenced block below into Claude Code running **in your company repo** (Opus 4.7,
> ~1M context, GitHub access). It assumes this `platform-cardinality-kit/` folder sits somewhere in that
> repo. It is **discovery-first** — it learns YOUR real layout before doing anything, and it never
> applies changes (it hands you the commands).

```text
You are operating in our company monorepo for a Grafana LGTM Platform-as-a-Product: app teams opt-in to
deploy an OpenTelemetry collector template on their OWN EKS clusters (10–200 nodes) that ship metrics to
a CENTRAL shared Mimir, isolated per team by X-Scope-OrgID. We have ~100 existing clusters (5–200 nodes)
plus a template newer teams adopt.

A kit folder `platform-cardinality-kit/` is in this repo. FIRST read, in full:
  - platform-cardinality-kit/KNOWLEDGE.md   (the correctness runbook + the MISTAKES LEDGER — obey it)
  - platform-cardinality-kit/TOOLCHAIN.md   (tools/MCPs to confirm are available)
  - platform-cardinality-kit/cardinality-reduction/SKILL.md + references/cookbook.md
This kit was proven on a reference sandbox; its file paths are PLACEHOLDERS. Do not assume them. Re-derive
and verify against THIS repo and OUR live Mimir — do not blindly copy.

GUARDRAILS (from the kit; non-negotiable):
- Never run terraform plan/apply or helm upgrade yourself — edit + validate, then hand me the exact
  command (with the right profile/region) to run.
- Consumption-gate every metric/label drop against the dashboards/rules REPO (not a kubectl get cm), at
  PromQL level (by()/{label=/group_left) — never substring grep.
- Two-tier, reversible-first; label hygiene at the per-team collector, NEVER the shared gateway.
- Validate every claim with a live query (Grafana MCP or curl); prefer trimmed CLI for bulk numbers.

STEP 0 — DISCOVER OUR LAYOUT (do this before anything; then show me a short summary and confirm):
  - The telemetry/cluster TEMPLATE: the OTel collector manifests/CRs/Helm app teams deploy (node tier,
    cluster tier, gateway, logs/events). Where, and what mode each is.
  - The Grafana DASHBOARDS/RULES source repo+dir (JSON/jsonnet/yaml) and how they're published (e.g. TF
    Grafana provider vs ConfigMap) — this is the consumption source of truth.
  - The central Mimir query endpoint + how to reach it (svc/port/path) and the per-tenant header; the
    ruler config location.
  - The gateway's resource_to_telemetry_conversion + add_metric_suffixes settings.
  - The list of tenants (X-Scope-OrgID) and, if available, a cluster→tenant inventory.
  Map each discovered path to the kit's placeholders. STOP and confirm with me if anything is ambiguous.

TRACK A — the reusable NEW-TEAM template (greenfield):
  Produce/upgrade our template to be hardened AND low-cardinality by construction, per KNOWLEDGE §1,§9,§10:
  4-tier (node DS / cluster STS+TA / gateway / logs+events), the global scrape guardrails, health_check,
  nodeSelector, priorityClass, DS updateStrategy, TA minReplicas 2; the cardinality defaults (cAdvisor
  keep-list, exporter denylists, the per-collector label dedup + scope-clear, whole-family histogram
  drops); validate each .spec.config offline with otelcol validate. Output the diffs + the apply commands;
  do NOT apply.

TRACK B — reduce cardinality on EXISTING tenants (brownfield), read-only:
  For each tenant (start with the largest by active series):
    1. baseline-before:  MIMIR_TENANT=<org> platform-cardinality-kit/cardinality-reduction/baseline.sh baseline-<org>-before.txt
    2. analyze:          MIMIR_TENANT=<org> platform-cardinality-kit/cardinality-reduction/analyze.sh --dashboards-dir <DASHBOARDS_REPO> --out report-<org>.txt
       (set MIMIR_NS/MIMIR_SVC/MIMIR_PATH for our gateway)
    3. From the report, propose drops down the lever ladder (KNOWLEDGE §3), consumption-gated, whole-family
       for histograms (§5), at the producer for labels (§4). Write the config diffs per component/tenant.
    4. Hand me the apply commands. After I apply: re-baseline, diff, confirm up==0 unchanged, no new dup,
       joins resolve, samples_ingested down, consumed families intact. Record a per-job tracker table
       (OPTIMIZATION.md style) + the get-it-back note per drop.

DELIVERABLES:
  - Track A: the hardened+optimized template diffs + an apply runbook + offline-validation evidence.
  - Track B: per-tenant report-<org>.txt + baseline before/after diffs + the proposed reversible diffs +
    a fleet rollup (series saved per tenant) + the per-job tracker.
  - A short "what differs from the kit's reference" note (where our stack diverges).
  - Flag the SCALE gaps (KNOWLEDGE §12): per-tenant Mimir limits, cost attribution, a CI baseline-diff
    gate, drift detection, cardinality SLO/alert — propose how to add them.

Begin with STEP 0 and report back before changing anything.
```
