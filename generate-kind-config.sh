#!/bin/bash

# Βρες το absolute path του project root
PROJECT_ROOT="$(pwd)"

# Δημιούργησε το kind-config.yaml με το σωστό path
sed "s|HOSTPATH_PLACEHOLDER|$PROJECT_ROOT/jenkins_home|g" kind-config-template.yaml > kind-config.yaml

echo "kind-config.yaml created with hostPath: $PROJECT_ROOT/jenkins_home" 