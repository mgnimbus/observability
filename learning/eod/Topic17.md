# Topic 17 — Receivers (the pipeline entry) — PREVIEW DRAFT

> ⚠ **PREVIEW / pre-teaching draft (2026-06-18, phone revision).** Not a post-mastery gold doc. We
> **resume live** — assess → teach → ground → brutal quiz. Quiz below has **NO answers**; attempt cold.
> Anchor idea: **a receiver is how telemetry ENTERS a pipeline, and it is either PUSH (something sends
> to it) or PULL (it goes and scrapes).** Your collector runs both — the `otlp` push receiver and the
> `prometheus` pull receiver — which is exactly the "two dialects" seam from T14.

---

## WHY they exist
The pipeline needs a typed entry point that speaks each source's protocol and normalizes it into the
internal OTel data model (the pdata model: Resource → Scope → Metric/Span/Log). Receivers are what
make the Collector **omnivorous** — OTLP, Prometheus scrape, host metrics, kubelet, k8s objects/events,
filelog, statsd, jaeger, zipkin, kafka, etc.

## WHAT a receiver is — push vs pull
| | **Push receivers** | **Pull receivers** |
|---|---|---|
| Who initiates | the **source** sends to the receiver | the **receiver** opens the connection and scrapes |
| Examples | `otlp` (gRPC 4317 / HTTP 4318), `loki`, `statsd`, `jaeger`, `zipkin`, `kafka` | `prometheus` (scrape), `hostmetrics`, `kubeletstats`, `k8sobjects` (watch/pull), `filelog` (tail) |
| Liveness | source's responsibility | receiver emits `up`/scrape metrics |
| Backpressure | receiver can refuse (returns error to sender) | receiver paces its own scrape |

This is the same **push-vs-pull = who opens the TCP connection** rule from T5. The Collector is the
**pull→push pivot**: a `prometheus` *pull* receiver feeding a `prometheusremotewrite` *push* exporter.

## The receivers that matter
- **`otlp`** — the native push entry; gRPC `:4317`, HTTP `:4318`. All three signals. `include_metadata`
  surfaces headers (we use it for `X-Scope-OrgID`). `max_recv_msg_size_mib` bounds large batches.
- **`prometheus`** — runs a Prometheus scrape loop *inside* the collector; in our stack its targets
  come from the **Target Allocator** (not static configs) — the TA does SD + sharding, the receiver
  does the HTTP GET + parse + `up`/`scrape_*`. Supports native-histogram scraping with
  `scrape_protocols: [PrometheusProto, …]` + `scrape_native_histograms: true`.
- **`hostmetrics`** — node CPU/mem/disk/net/filesystem (the node-exporter analog, OTel-native;
  agent/DaemonSet only).
- **`kubeletstats`** — pulls the kubelet Summary API for pod/container/volume stats (needs
  `nodes/stats` RBAC).
- **`k8sobjects`** — watches/pulls K8s API objects & events (the events live under
  `body["object"]["type"]` — a known shape gotcha).
- **`filelog`** — tails container log files; `recombine` for multiline, runs as root, needs host log
  mounts (the log-collection path for Phase 2).

## Grounded in MY stack (live config)
- **Gateway** receives **`otlp` only** (`grpc :4317` `max_recv_msg_size_mib: 250` `include_metadata:
  true`; `http :4318`) — because apps and the per-team collectors **push** to it. A gateway scrapes
  nothing.
- **Per-team collectors** run the **`prometheus`** receiver, fed by the **TA** (`meta_ta.yaml`) — this
  is where node-exporter/KSM/cAdvisor/Mimir-self get pulled (T8–T13). The TA hands the receiver the
  active target list via HTTP; the receiver scrapes and emits `up`/`scrape_*`.
- **Self-telemetry note (from our otel-observability work):** the collector daemonset chart renders no
  Service/ServiceMonitor → self-metrics are scraped via a **PodMonitor**; `service.name` → `job`.

## HOW it scales / trade-offs
- **Push receivers** scale with the **gateway** (more replicas absorb more senders); guard with
  `max_recv_msg_size_mib`, auth, and `memory_limiter` downstream.
- **Pull receivers** scale with the **target count**; the TA shards targets across collector replicas
  (`per-node` vs `consistent-hashing`) so no one collector scrapes everything.
- A receiver you **declare but don't reference** in a pipeline ingests nothing; a receiver you
  **enable but mis-scope** (RBAC, host mounts) silently gets partial/zero data.

## Common failure modes (to explore live)
- `otlp` size limits too low → large batches **refused** (`otelcol_receiver_refused_*` climbs).
- `prometheus` receiver with a stale/empty TA list → jobs vanish from `/jobs` (T6/T13).
- `kubeletstats`/`k8sobjects` missing RBAC → empty data, no crash.
- `filelog` without host mounts or wrong `include` globs → no logs; multiline without `recombine` →
  split stack traces.
- Receiver not referenced in any pipeline → silently inert (same trap as processors/exporters).

## Troubleshooting approach
- `otelcol_receiver_accepted_*` vs `otelcol_receiver_refused_*` per receiver → is data entering at all?
- For `prometheus`: the TA `/jobs` + `/targets` + `up==0` ladder (T6).
- For push receivers: check the **sender** (SDK endpoint, TLS, tenant header) — the gap is often
  upstream of the receiver.

## Interview questions (later)
- Classify `otlp`, `prometheus`, `hostmetrics`, `filelog`, `k8sobjects` as push or pull and justify by
  "who opens the connection."
- In our stack, which receiver lives on the gateway and which on the per-team collectors, and why does
  the gateway scrape nothing?
- How does the `prometheus` receiver get its targets without static configs?
- What RBAC/host-mount prerequisites silently zero-out `kubeletstats` / `filelog`?

## Practical exercises (live)
1. Confirm the gateway has only an `otlp` receiver and the per-team collectors have the `prometheus`
   receiver; map each to push/pull.
2. Read `otelcol_receiver_accepted_metric_points` per receiver; correlate the `prometheus` one with the
   TA's active target count.
3. (Phase 2 preview) Inspect the `filelog` receiver's `include` globs + `recombine` config.

## Memorize (one-liners)
- Receiver = pipeline entry; **push** (source sends: `otlp`, `loki`, `statsd`) vs **pull** (receiver
  scrapes: `prometheus`, `hostmetrics`, `kubeletstats`, `filelog`).
- Collector = pull→push pivot; `prometheus` receiver targets come from the **TA**, not static configs.
- Our gateway = `otlp` only (apps/collectors push to it); per-team collectors = `prometheus` (TA-fed).
- Unreferenced/mis-scoped receiver = silent zero data; watch `receiver_accepted` vs `_refused`.

## Quiz — attempt cold (NO answers; graded live on resume)
1. Why does the gateway run **no** `prometheus` receiver while the per-team collectors do? Tie it to
   push-vs-pull and to where the TA sits.
2. An app's OTLP metrics stop arriving; `otelcol_receiver_refused_metric_points` is climbing on the
   gateway. Name two `otlp` receiver settings to check and the sender-side cause each maps to.
3. The `prometheus` receiver shows a job with 0 targets even though the workload is healthy. Walk the
   discovery funnel that produces 0, naming the TA's role.
4. You enable `kubeletstats` and `k8sobjects` but both return empty with no errors. What's the common
   class of root cause, and how do you confirm it?
5. Classify each as push or pull and state who opens the connection: `otlp`, `prometheus`,
   `hostmetrics`, `kafka`, `filelog`.
