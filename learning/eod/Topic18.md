# Topic 18 — Exporters (OTel, the pipeline exit) — PREVIEW DRAFT

> ⚠ **PREVIEW / pre-teaching draft (2026-06-18, phone revision).** Not a post-mastery gold doc. We
> **resume live** — assess → teach → ground → brutal quiz. Quiz below has **NO answers**; attempt cold.
> Anchor idea: **an exporter is how telemetry LEAVES the collector toward a backend — and it owns the
> wire format, the tenant/auth headers, TLS, compression, and the reliability machinery
> (`sending_queue` + `retry_on_failure`).** In our stack one collector fans **one OTLP stream out to
> three different backends** via three different exporters.

---

## WHY they exist
The same internal telemetry must reach backends that speak different protocols (Prometheus remote
write, OTLP, Loki push) with different tenancy/auth. The exporter is the **translation + delivery +
reliability** boundary, so the rest of the pipeline stays backend-agnostic.

## WHAT an exporter is
The pipeline exit component. It (1) **serializes** to the backend's wire format, (2) attaches
**auth/tenant headers** + **TLS**, (3) **compresses**, and (4) manages **delivery reliability** via a
queue and retries. Like all components it must be **referenced in a `service::pipelines` exporter
list** to do anything.

## The exporters that matter (our stack + usual)
| Exporter | Backend / format | Notes |
|---|---|---|
| **`prometheusremotewrite`** | Mimir (Prometheus RW) | the T14 metric translation lives here (sanitize, `add_metric_suffixes`, `target_info`, flatten); RW **v1** today (v2 needed for exemplars) |
| **`otlp`** | Tempo (OTLP gRPC) | traces; `headers_setter` auth |
| **`otlphttp/loki`** | Loki (OTLP HTTP) | logs; tenant header |
| **`debug` / `logging`** | stdout | dev/troubleshooting; never in prod path |
| `prometheus` | local `/metrics` (pull) | the *pull* exporter (rare here); supports native histograms but **no exemplars** |
| `kafka`, `file`, `loadbalancing` | queues/sinks/fan-out | `loadbalancing` keeps a trace's spans on one backend |

## The shared machinery (applies to most exporters)
- **`sending_queue`** — in-memory (or persistent via `file_storage`) buffer; `queue_size`,
  `num_consumers`. Absorbs backend slowness; full queue → drop.
- **`retry_on_failure`** — exponential backoff on retryable errors; `max_elapsed_time` bounds it.
- **`auth` / `headers_setter`** — per-request tenant/auth (our `X-Scope-OrgID` `from_context`).
- **`tls`** — CA pinning vs `insecure_skip_verify` (per-cluster in our per-team configs).
- **`compression`** — `snappy` for PRW/OTLP (we use snappy on the per-team→gateway OTLP hop).

## Grounded in MY stack (live config)
- **Gateway** (`_8_otel_collector/manifests/values.yaml`) fans out to **three** backends:
  - `prometheusremotewrite` → `${mimir_endpoint}`: `resource_to_telemetry_conversion.enabled: true`
    (flatten), `target_info.enabled: false` (out-of-order fix), `add_metric_suffixes: true`,
    `auth: headers_setter`. **This is the T14 translation boundary.**
  - `otlp` → `${tempo_endpoint}` (traces), `auth: headers_setter`.
  - `otlphttp/loki` → `${loki_endpoint}` (logs), `auth: headers_setter`.
- **Per-team collectors** export **`otlp` → the gateway** (`endpoint: ${obsrv_domain_name}`,
  `compression: snappy`, `tls` CA-pin option, `headers: X-Scope-OrgId: ${tenant}`). So the tenant is
  stamped at the per-team hop and re-propagated by the gateway's `headers_setter` from gRPC metadata.
- **Reliability today:** queues/retries are largely defaults — a live audit (when back) should confirm
  `sending_queue`/`retry_on_failure` sizing and whether a **persistent queue** (file_storage) is
  warranted for restart-survival.

## HOW it scales / trade-offs
- **Queue + retries** trade memory/latency for durability under backend slowness; **persistent queue**
  survives restarts but needs a volume and adds I/O.
- **Compression** trades CPU for network/egress (relevant on the NLB ingestion + cross-AZ).
- **PRW v1 vs v2**: v2 unlocks exemplars + native-histogram exemplars but needs both ends to support
  it — a deliberate upgrade, not a flag flip.
- **Fan-out cost**: each exporter is an independent delivery path with its own failure mode; one slow
  backend shouldn't stall the others (separate queues).

## Common failure modes (to explore live)
- **Wrong/missing tenant header** → data in the wrong tenant or 401 (the classic "data disappeared").
- **Delta metrics** hit `prometheusremotewrite` → **dropped** (T14) → missing series.
- **Queue full** (slow Mimir) → `otelcol_exporter_send_failed_*` + drops; no persistent queue → restart
  loses buffered data.
- **TLS misconfig** (`insecure_skip_verify` vs CA pin) → handshake failures or silent insecurity.
- **Exporter not referenced** in a pipeline → telemetry computed then thrown away.
- **Exemplars on, PRW v1** → `written_exemplars` stays 0 (T14 gate 1).

## Troubleshooting approach
- `otelcol_exporter_sent_*` vs `otelcol_exporter_send_failed_*` + `otelcol_exporter_queue_size` per
  exporter → is it delivering, failing, or backpressured?
- Tenant issues: confirm `X-Scope-OrgID` on the actual write (headers_setter + metadata_keys path).
- Backend-side: only after the exporter is cleared, move to Mimir distributor / Loki / Tempo.

## Interview questions (later)
- What four responsibilities does an exporter own beyond "send"?
- Why might one slow backend NOT stall the others, and what makes that true or false in a config?
- Where exactly does the OTel→Prometheus translation happen, and which flags change it (tie to T14)?
- `sending_queue` vs persistent queue: what does each protect against, and the cost of each?

## Practical exercises (live)
1. List the gateway's three exporters and, for each, the endpoint + auth + the failure metric you'd
   watch.
2. Force a tenant-header mistake in a scratch pipeline and observe the 401 / wrong-tenant symptom.
3. Read `otelcol_exporter_queue_size` under load; reason about whether a persistent queue is justified.

## Memorize (one-liners)
- Exporter owns: **serialize + auth/tenant + TLS + compression + reliability (queue/retry)**.
- Our gateway fans **one stream → three backends**: PRW→Mimir, OTLP→Tempo, OTLP-HTTP→Loki, all via
  `headers_setter`.
- The **T14 metric translation lives in `prometheusremotewrite`** (flatten / `target_info` / suffixes);
  RW **v1** today → no exemplars.
- Reliability = `sending_queue` (+`file_storage` for persistence) + `retry_on_failure`; full queue =
  drop; restart without persistence = loss.

## Quiz — attempt cold (NO answers; graded live on resume)
1. Our gateway exports to Mimir, Tempo, and Loki. Mimir goes slow. Under what config does that stall
   Tempo/Loki writes, and under what config does it not?
2. A team's metrics vanish from Mimir but their traces still reach Tempo. Give two exporter-layer causes
   that would hit metrics-only.
3. Exactly where does `service.name` become `job`, and which exporter setting would *also* put it on the
   series as a label? Name the flag and its cost.
4. You want exemplars end-to-end. Name every exporter/back-end change required and the one counter that
   proves the collector side is working.
5. `sending_queue` is full and the collector restarts. With the default (in-memory) queue vs a
   `file_storage`-backed persistent queue, what happens to the buffered data in each case?
