# Cookbook — PromQL for cardinality work + the lever→mechanism map

All queries run against Mimir per tenant (`X-Scope-OrgID: <org>`). Quoting trap: inside a single-quoted
bash arg write matchers with plain `"` (`{job="x"}`) — escaped `\"` goes through literally and returns
empty. Prefer trimmed CLI: `curl -sG <base>/api/v1/query -H 'X-Scope-OrgID: <org>' --data-urlencode
'query=…' | jq -r '…'`.

## Find the waste
```promql
# active series for the tenant (the bill)
sum(cortex_ingester_memory_series)
# staleness-FREE ingest signal (trust this first; count() lags ~5m)
sum(scrape_samples_post_metric_relabeling)
# top metric FAMILIES by series (the firehoses)
topk(25, count by(__name__)({__name__=~".+"}))
# per-job /metrics size (maps to the exposition archetype)
avg by(job)(scrape_samples_post_metric_relabeling)
# family size by prefix
sum(count by(__name__)({__name__=~"container_.+"}))
```

## Labels: duplicate / constant / churn
```promql
# distinct values of a label on a metric (1 ⇒ constant/droppable; ≈series ⇒ churn)
count(count by(<label>)(<metric>))
# proof two labels are the SAME identity (duplicate): equal distinct counts + co-vary
count(count by(namespace)(<m>))  == count(count by(k8s_namespace_name)(<m>))
# dump one series' full label set (to spot k8s_*/service_*/server_*/otel_scope_* duplicates)
#   curl … 'query=<metric>' | jq -r '.data.result[0].metric | keys[]'
```

## Validation gates (run before AND after)
```promql
count(up)                                   # target inventory
count(up==0) or vector(0)                   # MUST stay flat (no scrape broke)
max(count by(<full identity>)(<metric>))    # MUST be 1 (no duplicate series)
count by(otel_collector_id)(<metric>)       # one collector owns a family
<m> * on(namespace,pod) group_left(node) kube_pod_info   # the rollup join still resolves
```
**Bad-dup-test caveat:** `count without(job,otel_collector_id)(<m>)` is WRONG — PromQL aggregation drops
`__name__`, so it counts metrics-per-target, not duplicate series. Always `count by(<full identity>)`.

## Spillage scan (families escaping a name-prefix drop)
```promql
sum(count by(__name__)({__name__=~"node_authorizer_.+"}))   # rides the apiservers job, dodges (apiserver|etcd)_
sum(count by(__name__)({__name__=~"authentication_.+|authorization_.+"}))
sum(count by(__name__)({__name__=~"apiserver_.+"}))         # also re-exposed on the kubelet job
sum(count by(__name__)({__name__=~"kube_apiserver_.+"}))    # dodges via the kube_ prefix
```

## Lever → mechanism map
| Lever | Where | Mechanism | Reversible? |
|---|---|---|---|
| drop object types KSM watches | KSM helm | `--resources=<list>` | redeploy |
| drop KSM metric families | KSM helm | `--metric-denylist=<regex>` (prefer over allowlist) | redeploy |
| disable node-exporter collectors | node-exporter helm | `extraArgs: --no-collector.<x>` | redeploy |
| node-exporter mount/iface trim | node-exporter helm | `--collector.filesystem.mount-points-exclude` / `--collector.netdev.device-exclude` | redeploy |
| node-exporter allowlist | SM | `prometheus.monitor.metricRelabelings` keep-list | **edit regex** |
| drop SM/PM metric families | SM/PM | `metricRelabelings` `action: drop` (whole-family for histograms) | **edit regex** |
| cAdvisor keep-list | scrape job | `metric_relabel_configs` `action: keep` (only lever — no native knob) | **edit regex** |
| set `node` on node-exporter | SM | `relabelings` `__meta_kubernetes_pod_node_name → node` | edit |
| drop duplicate resource labels | per-team collector | `resource` processor `action: delete` (k8s.*/server.*/url.scheme) | edit |
| drop scope labels | per-team collector | `transform` `context: scope` `set(name,"")`+`set(version,"")` | edit |
| drop a churn label | scraping collector | `metricRelabelings` `action: labeldrop`, `regex: uid` | edit |
| hard backstop | Mimir limits | `max_global_series_per_user` / `max_label_names_per_series` per tenant | edit |

## The OTLP-histogram rule (why a `_bucket`-only drop fails)
Prometheus exposition `_bucket`/`_sum`/`_count` → the OTel **receiver** assembles ONE OTLP histogram →
the gateway **PRW** `add_metric_suffixes` re-emits Prometheus series. Dropping only `_bucket` at scrape
leaves `_sum`/`_count`, so the receiver still builds a histogram and PRW re-emits a degenerate
`_bucket{le="+Inf"}`. **Drop `_(bucket|sum|count)` together** (receiver assembles nothing) or `filter`
the OTLP metric by name.
