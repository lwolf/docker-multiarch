#!/bin/bash

# declare -A targets=( ["amd64"]="amd64" ["arm64"]="arm64v8" ["arm"]="arm32v6" )
set -euo pipefail

export GITHUB_REPO=helm/helm
export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")

mkdir -p /tmp/release
for ARCH_TARGETS in amd64_amd64 arm64_arm64v8 arm_arm32v6
do
    TARGET=${ARCH_TARGETS#*_}  # will drop begin of string up to first occur of `SubStr`
    ARCH=${ARCH_TARGETS%%_*} # will drop part of string from first occur of `SubStr` to the end
    wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
    cp linux-${ARCH}/{tiller,helm} .
    docker build -t lwolf/helm:${VERSION}-${ARCH} --build-arg target=${TARGET} .
    docker push lwolf/helm:${VERSION}-${ARCH}
    rm -Rf {tiller,helm} linux-${ARCH}
done

docker manifest create --amend \
    lwolf/helm:${VERSION} \
    lwolf/helm:${VERSION}-amd64 \
    lwolf/helm:${VERSION}-arm64 \
    lwolf/helm:${VERSION}-arm

docker manifest create --amend \
    lwolf/helm:latest \
    lwolf/helm:${VERSION}-amd64 \
    lwolf/helm:${VERSION}-arm64 \
    lwolf/helm:${VERSION}-arm

docker manifest push lwolf/helm:${VERSION}
docker manifest push lwolf/helm:latest
