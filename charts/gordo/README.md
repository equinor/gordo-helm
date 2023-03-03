# gordo

Main gordo helm chart.

## Minikube development manual


1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) and [helm](https://helm.sh/docs/intro/install/).
2. Install [minikube](https://minikube.sigs.k8s.io/docs/start/).

3. Add ingress addon to minikube:
```
minikube addons enable ingress
```
4. Install helm:
```
helm install gordo . -f dev/minikube-values.yaml
```
5. Checkout an IP address for gordo-controller:
```
> kubectl get ingress
NAME               CLASS   HOSTS         ADDRESS          PORTS   AGE
gordo-controller   nginx   gordo.local   <IP address>     80      4m
```
6. Add this IP address to [the hosts file](https://en.wikipedia.org/wiki/Hosts_(file)).
```
gordo.local <IP address>
```
