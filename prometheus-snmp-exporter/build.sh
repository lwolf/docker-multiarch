#!/bin/bash

set -euo pipefail

export GITHUB_REPO=prometheus/snmp_exporter
export VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/${GITHUB_REPO}/releases/latest | cut -d '/' -f 8)
export CLEAN_VERSION=${VERSION#*v}
export DOCKER_REPO=lwolf/snmp-exporter

docker manifest inspect ${DOCKER_REPO}:${VERSION} > /dev/null && echo "Version ${VERSION} is already exists" && exit 0

for ARCH_TYPE in amd64 arm64 arm
do
    if [ "$ARCH_TYPE" == "amd64" ];then
        export TARGET=amd64
        export QEMU_ARCH=x86_64
        export ARCH=amd64
    elif [ "$ARCH_TYPE" == "arm" ]; then
        export TARGET=arm32v6
        export QEMU_ARCH=arm
        export ARCH=armv6
    elif [ "$ARCH_TYPE" == "arm64" ]; then
        export TARGET=arm64v8
        export QEMU_ARCH=aarch64
        export ARCH=arm64
    else
        echo "unsupported architecture type"
        return 1
    fi

    # Get QEMU
    curl -sL -o qemu-${QEMU_ARCH}-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz && tar zx -f qemu-${QEMU_ARCH}-static.tar.gz

    wget -O- https://github.com/prometheus/snmp_exporter/releases/download/${VERSION}/snmp_exporter-${CLEAN_VERSION}.linux-${ARCH}.tar.gz | tar xvz
    cp snmp_exporter-${CLEAN_VERSION}.linux-${ARCH}/{snmp_exporter,snmp.yml} .

    # Build image
    docker build -t $DOCKER_REPO:${VERSION}-${ARCH}  --build-arg target=${TARGET} --build-arg qemu_arch=${QEMU_ARCH} .

    # Push image
    docker push ${DOCKER_REPO}:${VERSION}-${ARCH}

    rm -Rf {snmp_exporter,snmp.yml} snmp_exporter-${CLEAN_VERSION}.linux-${ARCH}
done

docker manifest create --amend \
    ${DOCKER_REPO}:${VERSION} \
    ${DOCKER_REPO}:${VERSION}-amd64 \
    ${DOCKER_REPO}:${VERSION}-arm64 \
    ${DOCKER_REPO}:${VERSION}-armv6

for OS_ARCH in linux_amd64 linux_arm64
do
    ARCH=${OS_ARCH#*_}
    OS=${OS_ARCH%%_*}

    docker manifest annotate \
        ${DOCKER_REPO}:${VERSION} \
        ${DOCKER_REPO}:${VERSION}-${ARCH} \
        --os ${OS} --arch ${ARCH}

done

docker manifest annotate \
    ${DOCKER_REPO}:${VERSION} \
    ${DOCKER_REPO}:${VERSION}-armv6 \
    --os linux --arch arm --variant v6

docker manifest push ${DOCKER_REPO}:${VERSION}
