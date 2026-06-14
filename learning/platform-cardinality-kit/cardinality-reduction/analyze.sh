#!/usr/bin/env bash
# analyze.sh — READ-ONLY cardinality assessment for one tenant on a central Mimir. Produces a ranked
# report (firehoses, duplicate/constant/churn labels, control-plane spillage, consumption cross-ref)
# and suggested, reversible drops. It NEVER changes anything — you review, then apply by hand.
#
#   MIMIR_TENANT=<org-id> ./analyze.sh [--dashboards-dir <path>] [--out report.txt] [--probe <metric>]
#
# Repo-AGNOSTIC. Cluster/tenant via env (same as baseline.sh): MIMIR_TENANT (REQUIRED), MIMIR_NS,
# MIMIR_SVC, MIMIR_PORT, MIMIR_PATH. --dashboards-dir = your Grafana dashboards/rules SOURCE repo
# (JSON/jsonnet/yaml) for consumption-gating; omit to skip the cross-ref. --probe = a metric whose
# label set to audit (default: the top metric by series).
#
# Method this encodes (see KNOWLEDGE.md): firehoses first; a metric NAME never identifies a source
# (job+instance do); duplicate labels add WIDTH+churn not series; consumption is gated against the REPO
# (substring grep on short names like id/name/uid lies — match at PromQL level); drops are reversible.
set -euo pipefail

NS="${MIMIR_NS:-mimir}"; SVC="${MIMIR_SVC:-mimir-nginx}"; PORT="${MIMIR_PORT:-18098}"
APIPFX="${MIMIR_PATH:-/prometheus}"
TENANT="${MIMIR_TENANT:?set MIMIR_TENANT to the X-Scope-OrgID to analyze}"
DASH_DIR=""; OUT="cardinality-report-${TENANT}-$(date -u +%Y%m%dT%H%M%SZ).txt"; PROBE=""
while [ $# -gt 0 ]; do case "$1" in
  --dashboards-dir) DASH_DIR="$2"; shift 2;;
  --out) OUT="$2"; shift 2;;
  --probe) PROBE="$2"; shift 2;;
  *) echo "unknown arg: $1" >&2; exit 2;;
esac; done

kubectl -n "$NS" port-forward "svc/$SVC" "${PORT}:80" >/tmp/analyze-mimir-pf.log 2>&1 &
PF_PID=$!; trap 'kill $PF_PID 2>/dev/null || true' EXIT
for _ in $(seq 1 15); do ss -ltn 2>/dev/null | grep -q ":${PORT}" && break; sleep 1; done
ss -ltn 2>/dev/null | grep -q ":${PORT}" || { echo "port-forward to $SVC failed" >&2; cat /tmp/analyze-mimir-pf.log >&2; exit 1; }

BASE="http://localhost:${PORT}${APIPFX}/api/v1/query"
q()       { curl -s -G "$BASE" -H "X-Scope-OrgID: ${TENANT}" --data-urlencode "query=$1"; }
scalar()  { q "$1" | jq -r '.data.result[0].value[1] // "0"'; }
# distinct values of <label> over <selector>
distinct(){ scalar "count(count by(${1})(${2}))"; }

# control-plane / known spillage prefixes (escape a name-regex drop via a different prefix)
SPILL='apiserver_ etcd_ authentication_ authorization_ node_authorizer_ kube_apiserver_'
# label families that are usually DUPLICATES (of plain target labels) or CONSTANT noise
REDUNDANT='k8s_namespace_name k8s_pod_name k8s_node_name k8s_container_name k8s_pod_uid k8s_daemonset_name k8s_replicaset_name service_name service_instance_id server_address server_port url_scheme otel_scope_name otel_scope_version'
# labels that typically CHURN (new value per restart) — high distinct-count is the tell
CHURNY='uid id name image container_id pod_uid'

# consumption check at PromQL level (NOT substring) — is <label-or-metric> actually used in dashboards?
consumed(){ [ -z "$DASH_DIR" ] && { echo "?"; return; }
  grep -rohE "by ?\([^)]*\b$1\b[^)]*\)|\b$1=\"|\b$1!=|\b$1=~|group_(left|right)\([^)]*$1|\b$1\{" "$DASH_DIR" 2>/dev/null | wc -l | tr -d ' '; }

{
  echo "# cardinality report — tenant ${TENANT}"
  echo "captured_utc  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "context       $(kubectl config current-context 2>/dev/null || echo '?')"
  echo "dashboards    ${DASH_DIR:-<none — consumption cross-ref skipped>}"
  echo
  echo "## totals"
  echo "active_series      $(scalar 'sum(cortex_ingester_memory_series)')"
  echo "samples_ingested   $(scalar 'sum(scrape_samples_post_metric_relabeling)')"
  echo "targets up/down    $(scalar 'count(up==1)') / $(scalar 'count(up==0) or vector(0)')"
  echo

  echo "## top 25 metric FAMILIES by series (the firehoses — attack these first)"
  q 'topk(25, count by(__name__)({__name__=~".+"}))' \
    | jq -r '.data.result[] | "\(.value[1])\t\(.metric.__name__)"' | sort -rn | nl -w2 -s'  '
  echo

  : "${PROBE:=$(q 'topk(1, count by(__name__)({__name__=~".+"}))' | jq -r '.data.result[0].metric.__name__ // "up"')}"
  echo "## label audit on probe metric: ${PROBE}  ($(scalar "count(${PROBE})") series)"
  echo "   labels present:"
  q "$PROBE" | jq -r '.data.result[0].metric | keys[]' | sed 's/^/     /'
  echo
  echo "### duplicate / redundant labels present on ${PROBE}  (drop = width + churn savings, not series)"
  for l in $REDUNDANT; do
    d=$(distinct "$l" "$PROBE")
    [ "$d" != "0" ] && printf '     %-22s distinct=%-6s consumed_in_dashboards=%s\n' "$l" "$d" "$(consumed "$l")"
  done
  echo
  echo "### CHURN labels on ${PROBE}  (distinct ≈ series ⇒ new series every restart)"
  s=$(scalar "count(${PROBE})")
  for l in $CHURNY; do
    d=$(distinct "$l" "$PROBE")
    [ "$d" != "0" ] && printf '     %-14s distinct=%-6s / series=%-6s consumed=%s\n' "$l" "$d" "$s" "$(consumed "$l")"
  done
  echo

  echo "## control-plane / SPILLAGE scan (families that escape a name-prefix drop)"
  for p in $SPILL; do
    n=$(scalar "sum(count by(__name__)({__name__=~\"${p}.+\"})) or vector(0)")
    [ "$n" != "0" ] && printf '     %-20s series=%-7s consumed=%s\n' "$p" "$n" "$(consumed "${p}")"
  done
  echo

  if [ -n "$DASH_DIR" ]; then
    echo "## consumption cross-ref — top 25 families: are they used by any dashboard/rule?"
    q 'topk(25, count by(__name__)({__name__=~".+"}))' | jq -r '.data.result[].metric.__name__' \
      | while read -r m; do fam="${m%%_*}_"; printf '     %-40s consumed=%s\n' "$m" "$(consumed "$m")"; done
  else
    echo "## consumption cross-ref  SKIPPED (pass --dashboards-dir <repo> to enable — REQUIRED before any drop)"
  fi
  echo

  echo "## suggested next actions (REVIEW — nothing applied)"
  echo "  1. For each firehose family with consumed=0: drop it (exporter-native if it has a knob, else"
  echo "     ServiceMonitor/PodMonitor metricRelabelings — tier-2 reversible). Whole-family for histograms"
  echo "     (_bucket|_sum|_count) — a _bucket-only drop is rebuilt by the OTLP round-trip."
  echo "  2. Redundant labels above (distinct>0, consumed=0): delete the RESOURCE attrs at the per-team"
  echo "     collector (k8s.*/server.*/url.scheme) + scope-clear (otel_scope_*). NOT at the shared gateway."
  echo "  3. Churn labels with consumed=0 (uid/id/name/image): labeldrop at the scraping collector."
  echo "  4. Spillage families with consumed=0: tighten the drop regex or flip the job to a keep-list."
  echo "  5. Re-baseline (baseline.sh before/after) + confirm up==0 unchanged + joins still resolve."
} | tee "$OUT"

echo >&2 "report written to $OUT"
