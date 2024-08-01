helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update


helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \        ☁️  eks ☸ obsrv 
    --namespace kube-system \
    --values /home/mgnimbus/work_dir/observability/_1.2_nginx_ingress/manifests/values.yaml