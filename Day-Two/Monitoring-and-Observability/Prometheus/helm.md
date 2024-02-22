## Install Metrics-Server in EKS

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl get deployment metrics-server -n kube-system
```

## Add helm repositories for Prometheus

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

## Install Prometheus
```
helm upgrade -i prometheus prometheus-community/prometheus --namespace monitoring --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2 --create-namespace"
```

## Verify the deployment, statefulsets, services, and configmaps get created in prometheus namespace
```
kubectl get deploy,service,configmap,statefulset -n monitoring
```

## port-forward the promtheus-server service to access the prometheus console

```
kubectl port-forward svc/prometheus-server -n prometheus 9090:80
```