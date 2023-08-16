## App Deployment

`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

`argocd login <argocd-server external ip>:80`

`argocd app create sockshopapp --repo https://github.com/microservices-demo/microservices-demo.git --path deploy/kubernetes/manifests --dest-server https://kubernetes.default.svc --dest-namespace sock-shop`
