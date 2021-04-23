#!/usr/bin/env bash

export PATH=$PATH:$HOME/go/bin
export HELM_HOME=$HOME/.helm

cd kube-prometheus && jb update && cd ..

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
cd grafana/charts 
for grafana in grafana promtail loki tempo ; 
  do 
    helm pull grafana/$grafana
    tar zxf ${grafana}-*.tgz
    rm -f ${grafana}-*.tgz
    echo "### only checking diff for tag and repository between ../${grafana}/values.yaml and chart ${grafana}/values.yaml"
    diff ../${grafana}/values.yaml ${grafana}/values.yaml |egrep "tag|repository"
  done 