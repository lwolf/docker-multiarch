#!/bin/bash

set -euo pipefail

export GITHUB_REPO=kubernetes/dashboard
export VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/${GITHUB_REPO}/releases/latest | cut -d '/' -f 8)
export DOCKER_REPO=lwolf/kubernetes-dashboard

docker manifest inspect ${DOCKER_REPO}:${VERSION} > /dev/null && echo "Version ${VERSION} is already exists" && exit 0

for ARCH in amd64 arm64 arm
do
    docker pull k8s.gcr.io/kubernetes-dashboard-${ARCH}:${VERSION}
    docker tag k8s.gcr.io/kubernetes-dashboard-${ARCH}:${VERSION} ${DOCKER_REPO}:${VERSION}-${ARCH}
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
done

docker manifest create --amend \
    ${DOCKER_REPO}:${VERSION} \
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
done

docker manifest push ${DOCKER_REPO}:${VERSION}
