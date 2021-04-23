#!/usr/bin/env bash

kubectx docker-desktop

DEPLOYDIR="deploy"

kubectl apply -f $DEPLOYDIR/namespaces.yaml
kubectl apply -f $DEPLOYDIR/prometheus/setup/
kubectl apply -f $DEPLOYDIR/prometheus/
kubectl apply -f $DEPLOYDIR/dashboards/
kubectl apply -f $DEPLOYDIR/loki-manifests.yaml
kubectl apply -f $DEPLOYDIR/promtail-manifests.yaml
kubectl apply -f $DEPLOYDIR/tempo-manifests.yaml
kubectl apply -f $DEPLOYDIR/agent-tempo.yaml
kubectl apply -f $DEPLOYDIR/grafana-manifests.yaml