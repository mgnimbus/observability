# TOOLCHAIN.md — what the company Claude Code env needs before running this kit

Set this up first; the kit assumes it. Nothing here is exotic — it's the same toolchain that proved the
work in the sandbox.

## CLIs (on PATH)
| Tool | Used for | Notes |
|---|---|---|
| `kubectl` | port-forward to Mimir, inspect CRDs/SMs/objects | always pass `-n <ns>` explicitly |
| `jq` | shape query JSON (the token-economy lever — project only what you need) | required by both scripts |
| `curl` | direct Mimir PromQL API (the CLI fallback to the MCP) | required by both scripts |
| `yq` | validate/edit collector + values YAML offline | `yq eval '.' <file>` to lint |
| `helm` (+ `helm diff`) | render charts; **`helm diff upgrade` before any upgrade** | never `--force` |
| `terraform` | the human applies (you only `validate`/hand commands) | **you never run plan/apply** |
| `stern` | live multi-pod log tail (debug a collector) | |
| `logcli` | Loki historical queries (logs-side consumption checks) | `--org-id=<tenant>` |
| `otelcol-contrib <ver> validate` | offline-validate a rendered `.spec.config` | matches the image tag; catches OTTL + filelog errors `kubectl --dry-run` can't |
| `ss` | port-forward readiness probe in the scripts | usually preinstalled |

## MCPs (wire into Claude Code)
| MCP | Used for | Gotcha |
|---|---|---|
| **grafana** | live PromQL/LogQL, dashboard/panel inspection, datasource checks | reachable via `kubectl -n <grafana-ns> port-forward svc/<grafana-mcp> 8000:8000`; if it dies mid-session, **restart the forward FIRST then `/mcp` reconnect** (order matters). Datasource UID for Mimir + the tenant header are platform-specific. **Token note:** for count/topk/series dumps, trimmed `curl|jq` is cheaper than the MCP's untrimmable JSON — use the MCP for dashboards/correctness, CLI for bulk numbers. |
| **context7** | current docs for OTel Operator/Collector, Mimir/Loki/Tempo, prometheus-operator | pull BEFORE asserting any version-sensitive config key/flag (e.g. SM `metricRelabelings` support, TA selectors, PRW options) |
| **mermaid** | architecture diagrams | fenced ```mermaid``` blocks render on GitHub/VSCode without it |
| **sequential-thinking** | walk multi-hop failure chains | optional |

## Skill
- **`cardinality-reduction/`** — drop this dir where your Claude Code discovers skills (e.g. a plugin/
  skills path), or just point the model at `cardinality-reduction/SKILL.md`. It carries `baseline.sh`,
  `analyze.sh`, and `references/cookbook.md`.

## Access the kit needs
- **Read** access to: the central Mimir query gateway (via kube context / port-forward), the Grafana
  dashboards/rules **source repo**, the telemetry/cluster **template repo**, the collector manifests.
- **No write** access required for Track B analysis — it's read-only; humans apply changes.
