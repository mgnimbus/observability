# Topic 16 — Processors (the in-flight stage) — PREVIEW DRAFT

> ⚠ **PREVIEW / pre-teaching draft (2026-06-18, phone revision).** Not a post-mastery gold doc. We
> **resume live** — assess → teach → ground → brutal quiz. Quiz below has **NO answers**; attempt cold.
> Anchor idea: **processors are an ORDERED chain that transforms/enriches/protects/batches telemetry
> between receiver and exporter. Order is semantics, not style** — `memory_limiter` first, `batch`
> last, enrich before you filter on the enriched field.

---

## WHY they exist
Raw telemetry off a receiver is rarely shippable as-is: it needs **enrichment** (k8s metadata,
tenant), **shaping** (drop cardinality, rename, redact PII), **protection** (memory limits), and
**efficiency** (batching). Doing this in the Collector means **no app changes** and **one place** to
enforce platform policy.

## WHAT a processor is
A component in the pipeline's `processors:` list that receives a batch of telemetry, mutates/filters
it, and passes it on. **The list is ordered** — each processor sees the output of the previous one.
The same processor type can appear in metrics, logs, and traces pipelines with different configs.

## The processors that matter (our stack + the usual suspects)
| Processor | Job | Gotcha |
|---|---|---|
| **`memory_limiter`** | refuse/drop telemetry before the collector OOMs | **must be first**; soft+hard limits |
| **`batch`** | group into fewer, larger exports | **near last**; per-tenant via `metadata_keys` |
| **`resource`** | add/delete/update **resource** attributes | our **label dedup** deletes `k8s.*`/`server.*` |
| **`attributes`** | add/update **data-point/span/log** attributes | we set `X-Scope-OrgId` `from_context` |
| **`transform` (OTTL)** | expression-based edits across contexts (resource/scope/datapoint/…) | **OTTL strings MUST be quoted** in YAML; we scope-clear `otel_scope_*` |
| **`k8sattributes`** | enrich with pod/ns/node/workload from the API | needs RBAC; pod IP → pod association |
| **`metricstransform`** | rename/aggregate metric names/labels | we rename `exported_*` → `*` |
| **`filter`** | keep/drop whole metrics/spans/logs by match | cardinality + cost lever |
| **`resourcedetection`** | detect cloud/host resource (region, instance) | env-specific detectors |
| **`tail_sampling`** (traces) | keep interesting traces, drop boring | stateful, gateway-only, memory-heavy |
| **`deltatocumulative` / `cumulativetodelta`** | flip temporality (T14) | stateful; `max_streams` cap |
| **`redaction` / `transform`** | strip PII/secrets | order: redact **before** export, after enrich |

## Order is semantics — the rules
1. **`memory_limiter` first** — the seatbelt only works if it sees data before everything else.
2. **`batch` last** (just before export) — batch the *final* shape; batching early then mutating wastes
   work and breaks per-tenant grouping.
3. **Enrich before you filter/route on the enriched field** — e.g. `k8sattributes` (adds `namespace`)
   must precede a `filter`/`resource` that keys on `namespace`.
4. **Mutate before you batch** so the batch reflects the shipped shape.
5. **Protect (redact) late** but before export, after the data is in final form.

## Grounded in MY stack (live config)
- **Gateway** (`values.yaml`): `batch` (`send_batch_size: 8192`, `timeout: 200ms`,
  `metadata_keys: [X-Scope-OrgId]`, `metadata_cardinality_limit: 30` → **per-tenant batches**);
  `resource` (insert `gateway=argus-otel-gateway`); `attributes` (`X-Scope-OrgId` `from_context`
  `upsert` — pulls the tenant out of gRPC metadata onto the data).
- **Per-team collectors** (`meta_metrics.yaml` / `meta_ta.yaml`) — the **label-hygiene** chain (T14
  cleanup):
  - `resource: {delete k8s.pod.name, k8s.namespace.name, k8s.node.name, server.address, url.scheme …}`
    — kill resource attrs the gateway flatten would duplicate onto every series.
  - `transform` (OTTL, `context: scope`): `set(name, "")` / `set(version, "")` — clear the constant
    `otel_scope_*` labels (note the **quoted** OTTL — an unquoted statement is a YAML error).
  - `metricstransform`: `^exported_(.*)$` → `$$${1}` — undo the `exported_` prefix from honor_labels.
- **`headers_setter`** is an **extension, not a processor** — it injects the tenant header on the
  *export* side; the `attributes`/`batch` `metadata_keys` carry it *through* the pipeline.

## HOW it scales / trade-offs
- **`batch`** is the throughput dial; bigger batches = fewer requests but more memory + latency.
- **`filter`/`resource`/`metricstransform`** are the **cardinality/cost** levers — the cheapest place
  to drop series before they hit Mimir (vs metricRelabelings at the SM, vs exporter-native limits;
  T9/T11 two-tier model).
- **Stateful processors** (`tail_sampling`, `deltatocumulative`, `cumulativetodelta`) hold per-stream
  state → memory grows with cardinality, restart loses state. Cap them.
- **`k8sattributes`** adds an API-watch cost + RBAC; do it at the agent (near the pod) when possible.

## Common failure modes (to explore live)
- **Wrong order**: `batch` before mutation; filtering on a label `k8sattributes` hasn't added yet;
  `memory_limiter` not first → OOM.
- **Unquoted OTTL** in `transform` → collector fails to start (config parse error).
- **Over-aggressive `filter`/`resource` delete** → a label a dashboard/alert consumes vanishes
  (always verify consumption first).
- **`metadata_keys` cardinality** unbounded → batch explosion (`metadata_cardinality_limit` caps it).
- Stateful processor with no `max_streams`/limit → memory creep → OOM.

## Troubleshooting approach
- `otelcol_processor_dropped_*` / `_refused_*` by processor → which stage is shedding.
- Reproduce with the **`debug`/`logging` exporter** on a copy pipeline to see the shape after each
  processor (add processors incrementally).
- Diff series before/after a `resource`/`filter` change with `baseline.sh` (per-topic optimize habit).

## Interview questions (later)
- Why is processor order semantic? Give two orderings that are *wrong* and the failure each causes.
- Where would you drop cardinality — processor `filter`, SM `metricRelabelings`, or exporter-native —
  and what's the trade-off (reversibility, ruler deps)?
- What's stateful about `tail_sampling` and `deltatocumulative`, and how do you bound their memory?
- How does our stack carry a tenant header through the pipeline using processors + an extension?

## Practical exercises (live)
1. Add a `debug` exporter on a scratch pipeline; observe a metric's labels before vs after the per-team
   `resource`/`transform`/`metricstransform` chain.
2. Find a label our `resource: delete` removes; prove (MCP/PromQL) that 0 dashboards/alerts use it.
3. Break the OTTL quoting on purpose in a dry-run render and read the parse error.

## Memorize (one-liners)
- Processors = ordered transform/enrich/protect/batch; **order is semantics**.
- `memory_limiter` first, `batch` last, enrich-before-filter, redact-before-export.
- Our label hygiene = `resource` delete + `transform` scope-clear (OTTL, **quoted**) +
  `metricstransform` `exported_*`→`*`, at the **per-team** collectors (not the shared gateway).
- Cardinality lever ladder: processor `filter`/`resource` (collector) · `metricRelabelings` (SM) ·
  exporter-native allow/deny.

## Quiz — attempt cold (NO answers; graded live on resume)
1. You add a `filter` that drops on `namespace`, but it drops nothing. The metrics are OTLP-push from
   an app. Give the most likely ordering bug and the fix.
2. Our `transform` clears `otel_scope_name`. Why does that *reduce label width but not series count*,
   and where in the pipeline must it sit relative to the gateway's flatten?
3. You must reduce a firehose metric's cardinality and keep the ability to bring it back without a
   redeploy. Pick the processor-vs-SM-vs-exporter layer and justify against ruler dependencies.
4. `deltatocumulative` and `tail_sampling` are both stateful. For each: what state, what bounds it, and
   what happens on a collector restart?
5. Why is `headers_setter` an extension while `attributes` (which also touches `X-Scope-OrgId`) is a
   processor? What does each actually do to the tenant header?
