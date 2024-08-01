kubectl port-forward -n kube-system svc/ingress-nginx-controller 8080:80

curl -sS localhost:8080/test-ingress

# To install and test ingress-nginx

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.2.3 \
    --namespace kube-system \
    --set controller.service.type=ClusterIP

kubectl -n kube-system rollout status deployment ingress-nginx-controller

kubectl get deployment -n kube-system ingress-nginx-controller