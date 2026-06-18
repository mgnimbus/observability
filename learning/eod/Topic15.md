# Topic 15 — OTel Collector (architecture) — PREVIEW DRAFT

> ⚠ **PREVIEW / pre-teaching draft (written 2026-06-18 for phone revision).** This is NOT a
> post-mastery gold doc yet. We **resume here, interactively, against the live cluster** — assess →
> teach → ground live → brutal quiz. Quiz at the bottom has **NO answers** by design; attempt cold.
> Anchor idea: **the Collector is a vendor-neutral telemetry *pipeline* — `receivers → processors →
> exporters`, wired per-signal under `service::pipelines`.** Everything else (agent vs gateway,
> scaling, the TA) is a deployment detail around that one shape.

---

## WHY it exists
Before the Collector, every backend had its own agent and every app spoke a vendor protocol. The
Collector is a **single, vendor-neutral process** that can **receive** any telemetry, **process**
(transform/enrich/protect/batch) it in flight, and **export** it to any backend — for **all three
signals**. It decouples *what apps emit* from *where it's stored*, so you can change backends, add
tenancy, drop cardinality, or redact PII **without touching app code**.

## WHAT it is — the pipeline model
```
receivers ─▶ processors (ordered) ─▶ exporters        (one pipeline per signal)
   │              │                       │
 entry        transform/enrich/         exit
 (push/pull)  protect/batch            (push)
```
- **Components are declared once** under `config:` and **referenced** into pipelines under
  `service::pipelines::{metrics,logs,traces}`. A component that's declared but **not referenced in a
  pipeline does nothing.**
- **Extensions** (`health_check`, `headers_setter`, `file_storage`, `pprof`, `zpages`) are
  pipeline-adjacent helpers — auth, health, persistent-queue storage — not in the data path itself.
- **Connectors** join two pipelines (e.g. `spanmetrics` turns traces → metrics); a component that is
  an exporter of one pipeline and a receiver of another.

## The two roles (same binary, different job)
| | **Agent** | **Gateway** |
|---|---|---|
| K8s shape | **DaemonSet** (1/node) | **Deployment** (central, HPA) |
| Job | collect node-local (host metrics, pod logs, local OTLP), enrich with k8s metadata, forward | aggregate from many agents/apps, apply tenancy + central policy, fan out to backends |
| Scales with | node count | traffic (replicas) |
| Risk | per-node blast radius 1 | central SPOF-ish (run ≥2 + HPA) |

A common topology is **agent → gateway → backends** (two tiers). The agent does cheap per-node work
near the source; the gateway does expensive shared work (tenancy, dedup, backend auth) once.

## Grounded in MY stack (live config)
- **Gateway** = `_8_otel_collector/manifests/values.yaml`: `mode: deployment`, `replicaCount: 1`
  (autoscales >1 — see the `target_info` race in T14). Receives **OTLP only** (`grpc :4317`
  `max_recv_msg_size_mib: 250`, `http :4318`); processors `batch` / `resource` / `attributes`;
  exporters `prometheusremotewrite`→Mimir, `otlp`→Tempo, `otlphttp/loki`→Loki; extensions
  `health_check` + `headers_setter`.
- **Per-team collectors** = `_meta_monitoring/manifests/meta_metrics.yaml` + `meta_ta.yaml`: a
  **`prometheus` receiver** scraping the TA-discovered targets, heavy processors (label dedup —
  `resource` delete, `transform` scope-clear, `metricstransform` `exported_*` rename), exporting
  **`otlp`→ the gateway** (`endpoint: ${obsrv_domain_name}`). So our shape is **per-team scraping
  collectors → shared gateway → LGTM**, with the **Target Allocator** doing SD/sharding for the
  scrapers (T4/T13).
- **Multi-tenancy is carried through the pipeline:** the `headers_setter` extension +
  `attributes`/`batch` `metadata_keys: [X-Scope-OrgId]` propagate the tenant header end-to-end so the
  exporters stamp the right `X-Scope-OrgID` on Mimir/Loki/Tempo writes.

## HOW it scales / trade-offs
- **Agent** scales with nodes (automatic via DaemonSet); **gateway** scales with traffic (HPA on CPU/
  memory or queue depth). Gateway autoscaling interacts badly with single-shared-series writes
  (the `target_info` out-of-order lesson) — know which writes are per-replica safe.
- **`batch`** trades a little latency for far fewer, larger export requests (throughput). **Tune**
  `send_batch_size`/`timeout`; per-tenant batching needs `metadata_keys`.
- **Backpressure**: `sending_queue` + `retry_on_failure` on exporters absorb backend slowness; a
  **persistent queue** (via `file_storage` extension) survives restarts but needs a volume.
- **`memory_limiter`** is the seatbelt — refuses/drops before OOM (must be first in the list).

## Common failure modes (to explore live)
- Component declared but **not referenced** in any pipeline → silently inert.
- **No `memory_limiter`** (or last in the chain) → OOMKilled gateway under load.
- Tenant header not propagated → data lands in the wrong/anonymous tenant.
- Agent vs gateway confusion: putting per-node work on the gateway, or central policy on the agent.
- Gateway single-replica = ingestion SPOF; >1 replica without per-replica-safe writes = out-of-order.

## Troubleshooting approach (debugging order: collector first)
1. Collector **logs** + internal telemetry (`otelcol_receiver_accepted_*`, `_refused_*`,
   `otelcol_processor_dropped_*`, `otelcol_exporter_sent_*`/`_failed_*`, queue size).
2. Is the data even **entering** (receiver accepted > 0)? Then is a **processor dropping**? Then is an
   **exporter failing** (auth/endpoint/backpressure)?
3. Only after the collector is cleared do you move downstream to Mimir/Loki/Tempo.

## Interview questions (to attempt later)
- Draw the three-part pipeline and place agent vs gateway responsibilities on it.
- Why must `memory_limiter` be first and `batch` near last?
- What's a connector, and give one metrics-from-traces example.
- How does the Collector enforce multi-tenancy without app changes, in our stack specifically?

## Practical exercises (live cluster — when back)
1. Dump the gateway's `service::pipelines` and list, per signal, the exact receiver/processor/exporter
   chain. Find any declared-but-unreferenced component.
2. Port-forward the collector's internal metrics; correlate `otelcol_receiver_accepted_metric_points`
   vs `otelcol_exporter_sent_metric_points` and explain any gap.
3. Trace one tenant's `X-Scope-OrgID` from gRPC metadata → `headers_setter` → the Mimir write.

## Memorize (one-liners)
- Collector = `receivers → processors → exporters`, wired per-signal in `service::pipelines`;
  unreferenced = inert.
- Agent (DaemonSet, per-node, cheap-local) vs Gateway (Deployment, central, tenancy + fan-out).
- `memory_limiter` first, `batch` last; backpressure = `sending_queue` + `retry_on_failure`
  (+`file_storage` for persistence).
- Our shape: per-team `prometheus`-receiver scrapers (TA-driven) → OTLP → shared gateway → LGTM.

## Quiz — attempt cold (NO answers provided; we grade live on resume)
1. A metric arrives at the gateway but never reaches Mimir, and the collector logs are clean. Name the
   three internal-telemetry counters you'd read **in order** to localize where it died, and what each
   tells you.
2. Our gateway is a Deployment that autoscales. Give one class of metric write that is **safe** across
   replicas and one that is **not**, and the mechanism behind the unsafe one.
3. Why do we run **per-team scraping collectors** feeding a **shared gateway** rather than one big
   collector? Give a tenancy reason and a blast-radius reason.
4. Place each on agent vs gateway and justify: host metrics, `X-Scope-OrgID` stamping, pod-log
   collection, cross-tenant cardinality policy.
5. What does a **connector** do that an exporter→receiver pair across two separate pipelines cannot,
   and name one you'd use for RED metrics.
