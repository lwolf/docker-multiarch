#!/bin/bash

set -euo pipefail

export GITHUB_REPO=coreos/flannel
# export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")
# export VERSION=v0.10.0
export VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/${GITHUB_REPO}/releases/latest | cut -d '/' -f 8)
export DOCKER_REPO=lwolf/flannel

for ARCH in amd64 arm64 arm
do
    docker pull quay.io/coreos/flannel:${VERSION}-${ARCH}
    docker tag quay.io/coreos/flannel:${VERSION}-${ARCH} ${DOCKER_REPO}:${VERSION}-${ARCH}
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
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

docker manifest push ${DOCKER_REPO}:${VERSION}
docker manifest push ${DOCKER_REPO}:latest
