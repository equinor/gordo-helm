## Development manual

### Install in minikube

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) and [helm](https://helm.sh/docs/intro/install/).
2. Start [minikube](https://minikube.sigs.k8s.io/docs/start/).

3. Add ingress addon to minikube:
```
minikube addons enable ingress
```
4. Install helm chart:
```
helm install gordo . -f dev/minikube-values.yaml
```
### Ingress connection

1. Checkout controller IP address:
```
> kubectl get ingress
NAME               CLASS   HOSTS         ADDRESS          PORTS   AGE
gordo-controller   nginx   gordo.local   <IP address>     80      4m
```
2. Add this IP address to [the hosts file](https://en.wikipedia.org/wiki/Hosts_(file)).
```
gordo.local <IP address>
```
3. Check connection:
```
curl gordo.local/gordo-controller/models
```
### Port-forward
Could be an alternative for [Ingress connection](#ingress-connection).

1. Port-forward controller's service:
```
kubectl port-forward service/gordo-controller 8080:80
```
2. Check connection:
```
curl gordo.local:8080/models
```

