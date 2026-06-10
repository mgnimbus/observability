#!/usr/bin/env bash
# Capture a diff-friendly snapshot of the metrics pipeline from Mimir, for before/after
# validation of a change. Run before a change and after, then `diff` the two output files.
#
#   ./baseline.sh                       # writes baseline-<UTC timestamp>.txt
#   ./baseline.sh after-relabel.txt     # writes to a named file
#   diff -u baseline-<before>.txt after-relabel.txt
#
# Queries Mimir directly via a temporary port-forward to svc/mimir-nginx (tenant: obsrv).
# Profile/region are irrelevant here — this only talks to the cluster in the current kube context.
#
# Collector topology — what each collector is responsible for (confirmed live via otel_collector_id):
#   obsrv-metrics-new  daemonset, per-node TA allocation, NO prometheusCR/CRD discovery.
#                      Owns ONLY the two static node jobs reached through the kubelet:
#                        - kubernetes-nodes           (kubelet  /metrics,          3 targets)
#                        - kubernetes-nodes-cadvisor  (kubelet  /metrics/cadvisor, 3 targets)
#                      Manifest: manifests/meta_metrics.yaml
#   obsrv-ta           statefulset, consistent-hashing TA, single match-all prometheusCR plane.
#                      Owns the static kubernetes-apiservers job PLUS every ServiceMonitor-
#                      discovered job: mimir/*, kube-state-metrics, prometheus-node-exporter,
#                      kube-dns, grafana, cert-manager, aws-load-balancer-controller, cainjector,
#                      webhook, otelcol-contrib, ...
#                      Manifest: manifests/meta_ta.yaml
#   The split is provable live by grouping on the otel_collector_id label (every sample is tagged
#   with its scraping collector by the attributes processor) — see "collector responsibility" below.
#   Nothing downstream consumes that label; it exists only to attribute a scrape to a collector.
set -euo pipefail

NS="${MIMIR_NS:-mimir}"
SVC="${MIMIR_SVC:-mimir-nginx}"
TENANT="${MIMIR_TENANT:-obsrv}"
PORT="${MIMIR_PF_PORT:-18099}"
OUT="${1:-baseline-$(date -u +%Y%m%dT%H%M%SZ).txt}"

kubectl -n "$NS" port-forward "svc/$SVC" "${PORT}:80" >/tmp/baseline-mimir-pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT
for _ in $(seq 1 15); do ss -ltn 2>/dev/null | grep -q ":${PORT}" && break; sleep 1; done
ss -ltn 2>/dev/null | grep -q ":${PORT}" || { echo "port-forward to $SVC failed" >&2; cat /tmp/baseline-mimir-pf.log >&2; exit 1; }

BASE="http://localhost:${PORT}/prometheus/api/v1/query"
LBL="http://localhost:${PORT}/prometheus/api/v1/label/__name__/values"
q()      { curl -s -G "$BASE" -H "X-Scope-OrgID: ${TENANT}" --data-urlencode "query=$1"; }
scalar() { q "$1" | jq -r '.data.result[0].value[1] // "—"'; }
# distinct metric-name count via the label API (cheaper/safer than a {__name__=~".+"} matcher)
names_count() { curl -s -G "$LBL" -H "X-Scope-OrgID: ${TENANT}" | jq -r '.data | length'; }
# emit "<value>\t<label>" lines, sorted by label so diffs are stable
table()  { q "$1" | jq -r '.data.result[] | "\(.metric.job // .metric.__name__ // "?")\t\(.value[1])"' | sort; }

{
  echo "# metrics baseline"
  echo "captured_utc       $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "kube_context       $(kubectl config current-context)"
  echo
  echo "## health"
  printf 'targets_total      %s\n' "$(scalar 'count(up)')"
  printf 'up_1               %s\n' "$(scalar 'count(up==1)')"
  printf 'up_0               %s\n' "$(scalar 'count(up==0) or vector(0)')"
  echo
  echo "## totals"
  printf 'samples_exposed    %s\n' "$(scalar 'sum(scrape_samples_scraped)')"
  printf 'samples_ingested   %s\n' "$(scalar 'sum(scrape_samples_post_metric_relabeling)')"
  printf 'ingester_mem_series %s\n' "$(scalar 'sum(cortex_ingester_memory_series)')"
  printf 'distinct_names     %s\n' "$(names_count)"
  echo
  echo "## collector responsibility  (collector  job  targets)"
  # which collector scrapes which job — the daemonset (obsrv-metrics-new) should hold ONLY the two
  # static kubelet jobs; everything else belongs to the statefulset (obsrv-ta). Sorted by collector
  # then job so the ownership split is visible at a glance and a job moving collectors shows in diff.
  q 'count by(otel_collector_id, job)(up)' \
    | jq -r '.data.result[] | "\(.metric.otel_collector_id // "?")\t\(.metric.job // "?")\t\(.value[1])"' | sort
  echo
  echo "## targets per job  (job  count)"
  table 'count by(job)(up)'
  echo
  echo "## ingested samples per job  (job  avg_post_relabel)"
  table 'avg by(job)(scrape_samples_post_metric_relabeling)'
  echo
  echo "## metric-family series counts  (family  series)"
  for fam in 'apiserver_' 'etcd_' 'thanos_objstore_' 'kube_' 'node_' 'container_' 'cortex_' 'go_' 'workqueue_' 'grafana_' 'otelcol_'; do
    printf '%-20s %s\n' "$fam" "$(scalar "sum(count by(__name__)({__name__=~\"${fam}.+\"})) or vector(0)")"
  done
  echo
  echo "## top 25 names by series"
  q 'topk(25, count by(__name__)({__name__=~".+"}))' \
    | jq -r '.data.result[] | "\(.value[1])\t\(.metric.__name__)"' | sort -rn
} | tee "$OUT"

echo >&2 "baseline written to $OUT"
