#!/usr/bin/env bash

kubectx docker-desktop

DEPLOYDIR="deploy"

kubectl delete -f $DEPLOYDIR/loki-manifests.yaml
kubectl delete -f $DEPLOYDIR/promtail-manifests.yaml
kubectl delete -f $DEPLOYDIR/tempo-manifests.yaml
kubectl delete -f $DEPLOYDIR/agent-tempo.yaml
kubectl delete -f $DEPLOYDIR/grafana-manifests.yaml
kubectl delete -f $DEPLOYDIR/prometheus/
kubectl delete -f $DEPLOYDIR/prometheus/setup/
kubectl delete -f $DEPLOYDIR/namespaces.yaml
