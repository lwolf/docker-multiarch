#!/bin/bash

set -euo pipefail

export QEMU_VERSION=v3.1.0-2
export export GITHUB_REPO=helm/helm
export TARGET=arm64v8
export QEMU_ARCH=aarch64
export ARCH=arm64
export VERSION=v2.12.2
export DOCKER_REPO=lwolf/helm


# Get QEMU
curl -sL -o qemu-${QEMU_ARCH}-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz && tar zx -f qemu-${QEMU_ARCH}-static.tar.gz

wget -O- https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-${ARCH}.tar.gz | tar xvz
cp linux-${ARCH}/{tiller,helm} .


# Build image
# docker run --rm --privileged multiarch/qemu-user-static:register
# cp Dockerfile.amd64 Dockerfile
docker build -t $DOCKER_REPO:${VERSION}-${ARCH}  --build-arg target=${TARGET} --build-arg qemu_arch=${QEMU_ARCH} .

# Push image
docker push ${DOCKER_REPO}:${VERSION}-${ARCH}
