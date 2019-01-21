ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="flannel-cni" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/flannel-cni" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apk update \
    && apk add ca-certificates \
    && rm -rf /var/cache/apk/*

COPY cni-plugins/* /opt/cni/bin/

ADD https://raw.githubusercontent.com/coreos/flannel-cni/master/install-cni.sh /install-cni.sh
ADD https://raw.githubusercontent.com/coreos/flannel-cni/master/flannel.conflist.default /flannel.conflist.default

RUN chmod +x /install-cni.sh
