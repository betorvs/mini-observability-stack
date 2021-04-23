#!/usr/bin/env bash

JSONNET="local.jsonnet"
DOMAIN="example.local"
GRAFANA_NAMESPACE="default"

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

export PATH=$PATH:$HOME/go/bin

manifests="manifests-${DOMAIN}"
prometheus="kube-prometheus"

# Make sure to start with a clean 'manifests' dir
rm -rf ${prometheus}/${manifests}
mkdir -p ${prometheus}/${manifests}/setup

# optional, but we would like to generate yaml, not json
jsonnet --ext-str customDomain="${DOMAIN}" -J ${prometheus}/vendor -m ${prometheus}/${manifests} ${prometheus}/"${JSONNET}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# clean up not yaml files
find ${prometheus}/${manifests} -type f ! -name "*.yaml" | xargs -I{} sh -c 'rm -f {}' -- {}

# patch node exporter daemonset for docker desktop
patch -p0 ${prometheus}/manifests-example.local/node-exporter-daemonset.yaml <${prometheus}/patch-node-exporter.yaml

# creating kubernetes-mixin grafana dashboards
mkdir -p ${prometheus}/dashboards
jsonnet -J ${prometheus}/vendor -m ${prometheus}/dashboards -e "(import \"kubernetes-mixin/mixin.libsonnet\").grafanaDashboards"
for file in $( ls ${prometheus}/dashboards/* )
  do 
    File=$(basename $file| cut -f1 -d"."| tr -d ' ')
    quoted_file=$(printf %q "$file" )
    eval kubectl create cm $File --from-file=${File}.json=$quoted_file -o yaml --dry-run=client --namespace ${GRAFANA_NAMESPACE} |kubectl label -f- --dry-run=client -o yaml --local grafana_dashboard="1" > ${prometheus}/dashboards/${File}.yaml
    rm -f $file
  done