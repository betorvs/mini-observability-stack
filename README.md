# mini observability stack

## Table of Contents
- [Overview](#overview)
- [Let's Play](#let's-play)
  - [Ingress](#ingress)
  - [How to access it](#how-to-access-it)
  - [Apply](#apply)
- [Example hotROD](#example-hotrod)
- [Example TNS](#example-tns)
  - [Explore TNS](#explore-TNS)
    - [Metrics -> Logs -> Traces](#Metrics-->-Logs-->-Traces)
    - [LogQLV2](#LogQLV2)
    - [Metrics -> Traces -> Logs](#Metrics-->-Traces-->-Logs)
  - [Remove all](#Remove-all)
- [Building steps](#Building-steps)
  - [Update helm charts and jsonnet](#Update-helm-charts-and-jsonnet)
  - [Build](#Build)
  - [Apply and check](#Apply-and-check)
  - [Remove](#Remove)
- [References](#References)

## Overview

Purpose of these repository is to aggregate prometheus-operator (using kube-prometheus jsonnet) with grafana stack with grafana Loki, grafana Tempo, grafana Agent and Grafana. Making it easy to demonstrate how grafana/prometheus observability works using examples like hotROD and TNS.

Then you can use this to create your own service monitors, prometheus rules and grafana dashboards. 

Tested on: Docker for MAC v3.3.0 with Kubernetes enabled v1.19.7

## Let's Play

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

If you want to check, please run `kubectl`:
```
$ kubectl get pods --all-namespaces | egrep -v "kube-system|ingress"
NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
default         grafana-85bcb4f4cf-n5pqc                    2/2     Running     0          8m14s
default         grafana-agent-traces-57bgj                  1/1     Running     0          8m17s
logging         loki-0                                      1/1     Running     0          8m21s
logging         promtail-9jtjf                              1/1     Running     0          8m21s
monitoring      alertmanager-main-0                         2/2     Running     0          8m20s
monitoring      kube-state-metrics-76f6cb7996-gdggq         3/3     Running     0          8m28s
monitoring      node-exporter-42d6s                         2/2     Running     0          8m27s
monitoring      prometheus-adapter-59df95d9f5-rxcfc         1/1     Running     0          8m26s
monitoring      prometheus-k8s-0                            2/2     Running     0          8m19s
monitoring      prometheus-operator-7775c66ccf-562ps        2/2     Running     0          8m35s
tracing         tempo-0                                     2/2     Running     0          8m18s
```

## Example hotROD

Deploy it:
```
kubectl apply -f examples/hotrod-example.yaml
```

To remove:
```sh
kubectl delete -f examples/hotrod-example.yaml
```

Access hotrod application using port-forward:
```
kubectl port-forward -n default $(kubectl get pods -n default -l 'app.kubernetes.io/component=hotrod' |grep example |awk '{print $1}') 8080
```

Choose your ride!

Access [grafana-local](http://grafana.example.local) and using `admin` and `strongpassword`.

In Explore: `{namespace="default",container="example-hotrod"}` and search for trace_id in one log line and click on it. Then click on "Tempo" button there.

## Example TNS 

Deploy TNS application
```sh
kubectl apply -f examples/tns-manifests.yaml
```

To remove:
```sh
kubectl delete -f examples/tns-manifests.yaml
```

### Explore TNS

#### Metrics -> Logs -> Traces
- Go to the TNS [Demo App Dashboard](http://grafana.example.local/d/62440ddb0b6b14e05c6cdd3940eda2d1/demo-app?orgId=1&refresh=10s)
- Zoom in on a section with failed requests if you are so inclined
- Panel Drop Down -> Explore
- Datasource Drop Down -> Loki
- Choose a log line with a traceID -> Tempo

#### LogQLV2
- Go to [Explore Tab Logs](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22loki%22,%7B%22exemplar%22:true,%22expr%22:%22%22%7D%5D)
- Choose Datasource Loki
- Run this query `{job="tns/app"} |json |line_format "{{.log}}" |logfmt | status>=500 and status <=599 and duration > 50ms`
- Choose a log line with a traceID -> Tempo

[Explore Tab Logs with line above](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22loki%22,%7B%22expr%22:%22%7Bjob%3D%5C%22tns%2Fapp%5C%22%7D%20%7Cjson%20%7Cline_format%20%5C%22%7B%7B.log%7D%7D%5C%22%20%7Clogfmt%20%7C%20status%3E%3D500%20and%20status%20%3C%3D599%20and%20duration%20%3E%2050ms%22%7D%5D)

#### Metrics -> Traces -> Logs
- Go to [Explore Tab Metrics](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22thanos%22,%7B%22exemplar%22:true%7D%5D)
- Choose Datasource thanos
- Run this query `histogram_quantile(.99, sum(rate(tns_request_duration_seconds_bucket{}[1m])) by (le))`
- Click an exemplar
- Click the log icon on a span line

[Explore Tab Metrics with histogram](http://grafana.example.local/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22thanos%22,%7B%22exemplar%22:true,%22expr%22:%22histogram_quantile(.99,%20sum(rate(tns_request_duration_seconds_bucket%7B%7D%5B1m%5D))%20by%20(le))%22,%22requestId%22:%22Q-6a284ac1-9aff-4be3-97f2-0b10b1518efc-0A%22%7D%5D)

### Remove all

```sh
./remove.sh
```


## Building steps

Required softwares:
- helm 3
- kubectl and kubectx
- jsonnet (go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb)
- gojsontoyaml (go get github.com/brancz/gojsontoyaml)
- docker-desktop with kubernetes enabled (can be minu-kube, not tested yet)

### Update helm charts and jsonnet

```sh
./update.sh
```

After upgrade all helm charts and jsonnet vendor directory, try to build it again.

### Build

```sh
./build.sh
```

### Apply and check

```sh
./apply.sh
```

You should have these pods deployed:
```
$ kubectl get pods --all-namespaces | egrep -v "kube-system|ingress"
NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
default         grafana-85bcb4f4cf-n5pqc                    2/2     Running     0          8m14s
default         grafana-agent-traces-57bgj                  1/1     Running     0          8m17s
logging         loki-0                                      1/1     Running     0          8m21s
logging         promtail-9jtjf                              1/1     Running     0          8m21s
monitoring      alertmanager-main-0                         2/2     Running     0          8m20s
monitoring      kube-state-metrics-76f6cb7996-gdggq         3/3     Running     0          8m28s
monitoring      node-exporter-42d6s                         2/2     Running     0          8m27s
monitoring      prometheus-adapter-59df95d9f5-rxcfc         1/1     Running     0          8m26s
monitoring      prometheus-k8s-0                            2/2     Running     0          8m19s
monitoring      prometheus-operator-7775c66ccf-562ps        2/2     Running     0          8m35s
tracing         tempo-0                                     2/2     Running     0          8m18s
```

If everything is working fine, you can try to use some examples application to test it.


### Remove
```sh
./remove.sh
```

## References

https://github.com/grafana/tns  

https://github.com/prometheus-operator/kube-prometheus  

https://grafana.com/docs/loki/latest/logql/  

https://github.com/grafana/agent  

https://github.com/grafana/tempo  

https://github.com/grafana/loki  

https://github.com/grafana/helm-charts/tree/main/charts  

https://github.com/jaegertracing/jaeger/tree/master/examples/hotrod   

