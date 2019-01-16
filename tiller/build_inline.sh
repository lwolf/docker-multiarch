#!/bin/bash

set -euo pipefail

export QEMU_VERSION=v3.1.0-2
export VERSION=v2.12.2
export DOCKER_REPO=lwolf/helm
export export GITHUB_REPO=helm/helm

for ARCH in amd64 arm64 arm
do
    if [ "$ARCH" == "amd64" ];then
        export TARGET=amd64
        export QEMU_ARCH=x86_64
        export ARCH=amd64
    elif [ "$ARCH" == "arm" ]; then
        export TARGET=armv6
        export QEMU_ARCH=arm
        export ARCH=arm
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET=arm64v8
        export QEMU_ARCH=aarch64
        export ARCH=arm64
    else
        echo "unknown architecture type"
        return 1
    fi

    # Get QEMU
    # curl -sL -o qemu-${QEMU_ARCH}-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz && tar zx -f qemu-${QEMU_ARCH}-static.tar.gz
    cp ../bin/qemu* .

    wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
    cp linux-${ARCH}/{tiller,helm} .

    # Build image
    docker build -t ${DOCKER_REPO}:${VERSION}-${ARCH} --build-arg target=${TARGET} --build-arg=${QEMU_ARCH} .

    # Push image
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

for ARCH in amd64 arm64
do
    ARCH=${OS_ARCH#*_}

    docker manifest annotate \
        ${DOCKER_REPO}:${VERSION} \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os linux --arch ${ARCH}

    docker manifest annotate \
        ${DOCKER_REPO}:latest \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os linux --arch ${ARCH}
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

