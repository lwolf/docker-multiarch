#!/bin/bash

set -euo pipefail

export GITHUB_REPO=helm/helm
export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")
export DOCKER_REPO=lwolf/helm

echo $GITHUB_REPO
echo $VERSION
echo $DOCKER_REPO

mkdir -p /tmp/release
for ARCH_TARGETS in amd64_amd64 arm64_arm64v8 arm_arm32v6
do
    TARGET=${ARCH_TARGETS#*_}  # will drop begin of string up to first occur of `SubStr`
    ARCH=${ARCH_TARGETS%%_*} # will drop part of string from first occur of `SubStr` to the end
    wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
    cp linux-${ARCH}/{tiller,helm} .
    docker build -t ${DOCKER_REPO}:${VERSION}-${ARCH} --build-arg target=${TARGET} .
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
    rm -Rf {tiller,helm} linux-${ARCH}
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
