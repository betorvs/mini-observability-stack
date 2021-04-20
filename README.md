# mini observability stack

## Play

We need an ingress and add new entries in /etc/hosts

### Ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.45.0/deploy/static/provider/cloud/deploy.yaml
```

[About ingress for Docker in Mac](https://kubernetes.github.io/ingress-nginx/deploy/#docker-for-mac)

### How to access it

Add it to `/etc/hosts`
```
127.0.0.1       grafana.example.local
127.0.0.1       alertmanager.example.local
127.0.0.1       prometheus.example.local
```

### Apply

```sh
./apply.sh
```

## Examples

### rothod

Deploy it:
```
kubectl apply -f examples/rothod-example.yaml
```

To remove:
```sh
kubectl delete -f examples/rothod-example.yaml
```

Access rothod application using port-forward:
```
kubectl port-forward -n default $(kubectl get pods -n default -l 'app.kubernetes.io/component=hotrod' |grep example |awk '{print $1}') 8080
```

Choose your ride!

Access [grafana-local](http://grafana.example.local) and using `admin` and `strongpassword`.

In Explore: `{namespace="default",container="example-hotrod"}` and search for trace_id in one log line and click on it. Then click on "Tempo" button there.

### tns application example

Deploy TNS application
```sh
kubectl apply -f examples/tns-manifests.yaml
```

To remove:
```sh
kubectl delete -f examples/tns-manifests.yaml
```

#### Explore TNS

##### Metrics -> Logs -> Traces
- Go to the TNS [Demo App Dashboard](http://grafana.example.local/d/62440ddb0b6b14e05c6cdd3940eda2d1/demo-app?orgId=1&refresh=10s)
- Zoom in on a section with failed requests if you are so inclined
- Panel Drop Down -> Explore
- Datasource Drop Down -> Loki
- Choose a log line with a traceID -> Tempo

##### LogQLV2
- Go to [Explore Tab Logs](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22loki%22,%7B%22exemplar%22:true,%22expr%22:%22%22%7D%5D)
- Choose Datasource Loki
- Run this query `{job="tns/app"} |json |line_format "{{.log}}" |logfmt | status>=500 and status <=599 and duration > 50ms`
- Choose a log line with a traceID -> Tempo

[Explore Tab Logs with line above](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22loki%22,%7B%22expr%22:%22%7Bjob%3D%5C%22tns%2Fapp%5C%22%7D%20%7Cjson%20%7Cline_format%20%5C%22%7B%7B.log%7D%7D%5C%22%20%7Clogfmt%20%7C%20status%3E%3D500%20and%20status%20%3C%3D599%20and%20duration%20%3E%2050ms%22%7D%5D)

##### Metrics -> Traces -> Logs
- Go to [Explore Tab Metrics](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22thanos%22,%7B%22exemplar%22:true%7D%5D)
- Choose Datasource thanos
- Run this query `histogram_quantile(.99, sum(rate(tns_request_duration_seconds_bucket{}[1m])) by (le))`
- Click an exemplar
- Click the log icon on a span line

[Explore Tab Metrics with histogram](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22thanos%22,%7B%22exemplar%22:true,%22expr%22:%22histogram_quantile(.99,%20sum(rate(tns_request_duration_seconds_bucket%7B%7D%5B1m%5D))%20by%20(le))%22,%22requestId%22:%22Q-6a284ac1-9aff-4be3-97f2-0b10b1518efc-0A%22%7D%5D)

## Building steps

## Build

```
cp namespaces/namespaces.yaml deploy/
cp grafana/agent/agent-tempo.yaml deploy/
helm template --release-name grafana --namespace default -f grafana/grafana/values.yaml ./grafana/charts/grafana > deploy/grafana-manifests.yaml
helm template --release-name loki --namespace logging -f grafana/loki/values.yaml ./grafana/charts/loki > deploy/loki-manifests.yaml
helm template --release-name promtail --namespace logging -f grafana/loki/values-promtail.yaml ./grafana/charts/promtail > grafana/loki/promtail-manifests.yaml
kustomize build grafana/loki/ > deploy/promtail-manifests.yaml
helm template --release-name tempo --namespace tracing -f grafana/tempo/values.yaml ./grafana/charts/tempo > grafana/tempo/tempo-manifests.yaml
kustomize build grafana/tempo/ > deploy/tempo-manifests.yaml
./kube-prometheus/build.sh
cp -r kube-prometheus/manifests-example.local deploy/prometheus
```

## Applying

```
kubectl apply -f deploy/namespaces.yaml
kubectl apply -f deploy/prometheus/setup/
kubectl apply -f deploy/prometheus/
kubectl apply -f deploy/loki-manifests.yaml
kubectl apply -f deploy/promtail-manifests.yaml
kubectl apply -f deploy/tempo-manifests.yaml
kubectl apply -f deploy/agent-tempo.yaml
kubectl apply -f deploy/grafana-manifests.yaml
```

## Deleting it

```
kubectl delete -f deploy/promtail-manifests.yaml
kubectl delete -f deploy/agent-tempo.yaml
kubectl delete -f deploy/grafana-manifests.yaml
kubectl delete -f deploy/loki-manifests.yaml
kubectl delete -f deploy/tempo-manifests.yaml
kubectl delete -f deploy/prometheus/
kubectl delete -f deploy/prometheus/setup/
kubectl delete -f deploy/namespaces.yaml
```


# References

https://github.com/grafana/tns  

https://github.com/prometheus-operator/kube-prometheus  

https://grafana.com/docs/loki/latest/logql/  

https://github.com/grafana/agent  

https://github.com/grafana/tempo  

https://github.com/grafana/loki  

https://github.com/grafana/helm-charts/tree/main/charts  