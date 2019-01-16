#!/bin/bash

set -euo pipefail

export GITHUB_REPO=helm/helm
# export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")
export VERSION=v2.12.2
export DOCKER_REPO=lwolf/helm

for ARCH in amd64 arm64 arm
do
    wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
    cp linux-${ARCH}/{tiller,helm} .
    cp ../bin/qemu* .
    docker build -t ${DOCKER_REPO}:${VERSION}-${ARCH} -f Dockerfile.${ARCH} .
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
    rm -Rf {tiller,helm} linux-${ARCH} qemu*
done

docker manifest create --amend \
    ${DOCKER_REPO}:${VERSION} \
    ${DOCKER_REPO}:${VERSION}-amd64 \
    ${DOCKER_REPO}:${VERSION}-arm64 \
    ${DOCKER_REPO}:${VERSION}-arm

docker manifest create --amend \
    ${DOCKER_REPO}:latest \
    ${DOCKER_REPO}:${VERSION}-amd64 \
    ${DOCKER_REPO}:${VERSION}-arm64 \
    ${DOCKER_REPO}:${VERSION}-arm

for OS_ARCH in linux_amd64 linux_arm linux_arm64
do
    OS=${ARCH_TARGETS#*_}
    ARCH=${ARCH_TARGETS%%_*}

    docker manifest annotate \
        ${DOCKER_REPO}:${VERSION} \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os ${OS} --arch ${ARCH}

    docker manifest annotate \
        ${DOCKER_REPO}:latest \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os ${OS} --arch ${ARCH}
done

docker manifest push ${DOCKER_REPO}:${VERSION}
docker manifest push ${DOCKER_REPO}:latest