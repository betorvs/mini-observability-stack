#!/usr/bin/env bash

JSONNET="local.jsonnet"
DOMAIN="example.local"

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
jsonnet --ext-str customDomain="${DOMAIN}" -J ${prometheus}/vendor -m ${prometheus}/${manifests} ${prometheus}/"${JSONNET}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}

# patch node exporter daemonset for docker desktop
patch -p0 ${prometheus}/manifests-example.local/node-exporter-daemonset.yaml <${prometheus}/patch-node-exporter.yaml
