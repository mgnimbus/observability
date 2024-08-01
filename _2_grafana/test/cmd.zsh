helm repo add grafana https://grafana.github.io/helm-charts
helm repo update


helm install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --set adminPassword='gowtham' \
  --set service.type=ClusterIP
