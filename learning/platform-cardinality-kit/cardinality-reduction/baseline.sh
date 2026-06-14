#!/usr/bin/env bash
# baseline.sh — diff-friendly snapshot of a metrics pipeline from Mimir, for BEFORE/AFTER validation
# of a cardinality change. Run before a change and after, then `diff -u` the two output files.
#
#   ./baseline.sh                         # writes baseline-<UTC timestamp>.txt
#   ./baseline.sh after-relabel.txt       # writes to a named file
#   diff -u baseline-<before>.txt after-relabel.txt
#
# Repo-AGNOSTIC. Everything cluster/tenant-specific is an env var — set these for YOUR platform:
#   MIMIR_TENANT   X-Scope-OrgID for the team/tenant you are baselining        (REQUIRED, no default)
#   MIMIR_NS       namespace of the Mimir query gateway service                (default: mimir)
#   MIMIR_SVC      the query gateway Service (proxies /prometheus/* )           (default: mimir-nginx)
#   MIMIR_PORT     local port-forward port                                      (default: 18099)
#   MIMIR_PATH     query API path prefix on the gateway                         (default: /prometheus)
#   FAMILIES       space-separated metric-name PREFIXES to size                 (default: the common set)
#
# Talks ONLY to the cluster in the current kube context, via a temporary port-forward — no AWS calls,
# profile/region irrelevant. Read-only (PromQL queries). Requires: kubectl, curl, jq, ss.
#
# NOTE on the staleness window: count()-based series numbers lag ~5 min after a drop lands (a series is
# counted while it still has a sample in the lookback). `samples_ingested` (post_metric_relabeling) is
# the staleness-FREE signal — trust it first; re-run count-based checks after ~5 min to confirm.
set -euo pipefail

NS="${MIMIR_NS:-mimir}"
SVC="${MIMIR_SVC:-mimir-nginx}"
PORT="${MIMIR_PORT:-18099}"
APIPFX="${MIMIR_PATH:-/prometheus}"
TENANT="${MIMIR_TENANT:?set MIMIR_TENANT to the X-Scope-OrgID you are baselining}"
OUT="${1:-baseline-$(date -u +%Y%m%dT%H%M%SZ).txt}"
# Metric-family prefixes to size. Override for your stack (e.g. add your app's prefix).
FAMILIES="${FAMILIES:-apiserver_ etcd_ kube_ node_ container_ go_ workqueue_ rest_client_ otelcol_ grafana_ cortex_ thanos_objstore_}"

kubectl -n "$NS" port-forward "svc/$SVC" "${PORT}:80" >/tmp/baseline-mimir-pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT
for _ in $(seq 1 15); do ss -ltn 2>/dev/null | grep -q ":${PORT}" && break; sleep 1; done
ss -ltn 2>/dev/null | grep -q ":${PORT}" || { echo "port-forward to $SVC failed" >&2; cat /tmp/baseline-mimir-pf.log >&2; exit 1; }

BASE="http://localhost:${PORT}${APIPFX}/api/v1/query"
LBL="http://localhost:${PORT}${APIPFX}/api/v1/label/__name__/values"
q()      { curl -s -G "$BASE" -H "X-Scope-OrgID: ${TENANT}" --data-urlencode "query=$1"; }
scalar() { q "$1" | jq -r '.data.result[0].value[1] // "—"'; }
names_count() { curl -s -G "$LBL" -H "X-Scope-OrgID: ${TENANT}" | jq -r '.data | length'; }
# emit "<job|name>\t<value>" lines, sorted, so diffs are stable
table()  { q "$1" | jq -r '.data.result[] | "\(.metric.job // .metric.__name__ // "?")\t\(.value[1])"' | sort; }

{
  echo "# metrics baseline"
  echo "captured_utc       $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "kube_context       $(kubectl config current-context 2>/dev/null || echo '?')"
  echo "tenant             ${TENANT}"
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
  # If your collectors stamp a per-scrape collector id (e.g. an attributes-processor 'otel_collector_id'),
  # this shows which collector owns which job — a job moving collectors shows in the diff. Falls back to
  # job-only if the label is absent.
  q 'count by(otel_collector_id, job)(up)' \
    | jq -r '.data.result[] | "\(.metric.otel_collector_id // "-")\t\(.metric.job // "?")\t\(.value[1])"' | sort
  echo
  echo "## targets per job  (job  count)"
  table 'count by(job)(up)'
  echo
  echo "## ingested samples per job  (job  avg_post_relabel)"
  table 'avg by(job)(scrape_samples_post_metric_relabeling)'
  echo
  echo "## metric-family series counts  (family  series)"
  for fam in $FAMILIES; do
    printf '%-20s %s\n' "$fam" "$(scalar "sum(count by(__name__)({__name__=~\"${fam}.+\"})) or vector(0)")"
  done
  echo
  echo "## top 25 names by series"
  q 'topk(25, count by(__name__)({__name__=~".+"}))' \
    | jq -r '.data.result[] | "\(.value[1])\t\(.metric.__name__)"' | sort -rn
} | tee "$OUT"

echo >&2 "baseline written to $OUT"
