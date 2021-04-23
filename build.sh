#!/usr/bin/env bash

DEPLOYDIR="deploy"

rm -rf $DEPLOYDIR

mkdir -p $DEPLOYDIR

cp namespaces/namespaces.yaml $DEPLOYDIR/
cp grafana/agent/agent-tempo.yaml $DEPLOYDIR/
helm template --release-name grafana --namespace default -f grafana/grafana/values.yaml ./grafana/charts/grafana > $DEPLOYDIR/grafana-manifests.yaml
helm template --release-name loki --namespace logging -f grafana/loki/values.yaml ./grafana/charts/loki > $DEPLOYDIR/loki-manifests.yaml
helm template --release-name promtail --namespace logging -f grafana/promtail/values.yaml ./grafana/charts/promtail > grafana/promtail/promtail-manifests.yaml
kustomize build grafana/promtail/ > $DEPLOYDIR/promtail-manifests.yaml
helm template --release-name tempo --namespace tracing -f grafana/tempo/values.yaml ./grafana/charts/tempo > grafana/tempo/tempo-manifests.yaml
kustomize build grafana/tempo/ > $DEPLOYDIR/tempo-manifests.yaml
./kube-prometheus/build.sh
cp -r kube-prometheus/manifests-example.local $DEPLOYDIR/prometheus
mkdir -p $DEPLOYDIR/dashboards
mv kube-prometheus/dashboards/*.yaml $DEPLOYDIR/dashboards