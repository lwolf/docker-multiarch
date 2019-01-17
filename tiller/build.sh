#!/bin/bash

set -euo pipefail

export GITHUB_REPO=helm/helm
# export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")
export VERSION=v2.12.2
export DOCKER_REPO=lwolf/helm

for ARCH in amd64 arm64 arm
do
    if [ "$ARCH" == "amd64" ];then
        export QEMU_VERSION=v3.1.0-2
        export export GITHUB_REPO=helm/helm
        export TARGET=amd64
        export QEMU_ARCH=x86_64
        export ARCH=amd64
        export VERSION=v2.12.2
        export DOCKER_REPO=lwolf/helm
    elif [ "$ARCH" == "arm" ]; then
        export QEMU_VERSION=v3.1.0-2
        export export GITHUB_REPO=helm/helm
        export TARGET=arm32v6
        export QEMU_ARCH=arm
        export ARCH=arm
        export VERSION=v2.12.2
        export DOCKER_REPO=lwolf/helm
    elif [ "$ARCH" == "arm64" ]; then
        export QEMU_VERSION=v3.1.0-2
        export export GITHUB_REPO=helm/helm
        export TARGET=arm64v8
        export QEMU_ARCH=aarch64
        export ARCH=arm64
        export VERSION=v2.12.2
        export DOCKER_REPO=lwolf/helm
    else
        echo "unknown architecture type"
        return 1
    fi

    # Get QEMU
    # curl -sL -o qemu-${QEMU_ARCH}-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz && tar zx -f qemu-${QEMU_ARCH}-static.tar.gz
    cp ../bin/qemu-${QEMU_ARCH}-static .

    wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
    cp linux-${ARCH}/{tiller,helm} .

    # Build image
    docker build -t $DOCKER_REPO:${VERSION}-${ARCH}  --build-arg target=${TARGET} --build-arg qemu_arch=${QEMU_ARCH} .

    # Push image
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}


done

# bash build.arm.sh
# bash build.arm64.sh
# bash build.amd64.sh

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
    ARCH=${OS_ARCH#*_}
    OS=${OS_ARCH%%_*}

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
