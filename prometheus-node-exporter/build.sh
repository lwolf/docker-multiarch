#!/bin/bash

set -euo pipefail

export GITHUB_REPO=prometheus/node_exporter
# export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")
export VERSION=v0.17.0
export CLEAN_VERSION=${VERSION#*v}
export DOCKER_REPO=lwolf/node-exporter

mkdir -p /tmp/release
for ARCH_TARGETS in amd64_amd64 arm64_arm64v8 armv6_arm32v6
do
    ARCH=${ARCH_TARGETS%%_*} # will drop part of string from first occur of `SubStr` to the end
    TARGET=${ARCH_TARGETS#*_}  # will drop begin of string up to first occur of `SubStr`
    wget -O- https://github.com/prometheus/node_exporter/releases/download/${VERSION}/node_exporter-${CLEAN_VERSION}.linux-${ARCH}.tar.gz | tar xvz
    cp node_exporter-${CLEAN_VERSION}.linux-${ARCH}/node_exporter .
    docker build -t ${DOCKER_REPO}:${VERSION}-${ARCH} --build-arg target=${TARGET} .
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
    rm -Rf {node_exporter} node_exporter-${CLEAN_VERSION}.linux-${ARCH}
done

docker manifest create --amend \
    ${DOCKER_REPO}:${VERSION} \
    ${DOCKER_REPO}:${VERSION}-amd64 \
    ${DOCKER_REPO}:${VERSION}-arm64 \
    ${DOCKER_REPO}:${VERSION}-armv6

docker manifest create --amend \
    ${DOCKER_REPO}:latest \
    ${DOCKER_REPO}:${VERSION}-amd64 \
    ${DOCKER_REPO}:${VERSION}-arm64 \
    ${DOCKER_REPO}:${VERSION}-armv6

for OS_ARCH in linux_amd64 linux_arm64
do
    OS=${OS_ARCH%%_*}
    ARCH=${OS_ARCH#*_}

    docker manifest annotate \
        ${DOCKER_REPO}:${VERSION} \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os ${OS} --arch ${ARCH}

    docker manifest annotate \
        ${DOCKER_REPO}:latest \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os ${OS} --arch ${ARCH}
done

docker manifest annotate \
    ${DOCKER_REPO}:${VERSION} \
    ${DOCKER_REPO}:${VERSION}-armv6 \
    --os linux --arch arm --variant v6

docker manifest annotate \
    ${DOCKER_REPO}:latest \
    ${DOCKER_REPO}:${VERSION}-armv6 \
    --os linux --arch arm --variant v6

docker manifest push ${DOCKER_REPO}:${VERSION}
docker manifest push ${DOCKER_REPO}:latest
