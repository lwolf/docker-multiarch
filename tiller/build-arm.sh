#!/bin/bash

set -euo pipefail

export GITHUB_REPO=helm/helm
export VERSION=v2.12.2
export DOCKER_REPO=lwolf/helm

mkdir -p /tmp/release
for ARCH_TARGETS in arm64_arm64v8
do
    TARGET=${ARCH_TARGETS#*_}  # will drop begin of string up to first occur of `SubStr`
    ARCH=${ARCH_TARGETS%%_*} # will drop part of string from first occur of `SubStr` to the end
    wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
    cp linux-${ARCH}/{tiller,helm} .
    docker build -t ${DOCKER_REPO}:${VERSION}-${ARCH} --build-arg target=${TARGET} .
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
    rm -Rf {tiller,helm} linux-${ARCH}
done
