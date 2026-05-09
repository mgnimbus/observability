# Observability platform — Claude conventions

## What this repo is
Internal observability platform on AWS EKS using the Grafana LGTM stack
(Loki, Grafana, Tempo, Mimir) with OpenTelemetry collectors.
Region: ap-south-2. Single primary AWS account. AWS profile: `obsrv`.

## Stack
- IaC: Terraform (no Terragrunt, no GitOps yet).
- Runtime: EKS clusters, Helm-deployed LGTM components.
- Telemetry: OpenTelemetry collectors fan-in to Loki/Tempo/Mimir.

## Hard rules
- Never run `terraform apply` / `destroy` without explicit confirmation.
- Never modify the `aws-auth` ConfigMap directly — it's owned by Terraform.
- Never edit Loki/Mimir retention or limits configs without confirmation.
- For Helm: prefer `helm diff upgrade` before `helm upgrade`. Never `--force`.

## Conventions
- Terraform modules under `terraform/modules/<name>`.
- Helm values under `helm/<chart>/values-<env>.yaml`.
- OTel collector configs under `otel/<env>/`.

## Operational notes
- Cluster context: prefer `kubectx` over manual KUBECONFIG manipulation.
- Logs: `stern` for live multi-pod tailing; `logcli` for cross-cluster historical LogQL.
- Traces: pull via Grafana UI; CLI workflows aren't worth the effort for traces.

## Debugging order
- OTel collector logs first → then Loki/Tempo/Mimir.
- EKS networking: VPC CNI logs → kube-proxy → CoreDNS.
- Ingestion latency: Mimir distributor metrics → ingester.
