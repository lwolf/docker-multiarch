ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="node-exporter" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/node-exporter" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apk update \
    && apk add ca-certificates socat \
    && rm -rf /var/cache/apk/* \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

COPY node_exporter /bin/node_exporter

EXPOSE      9100
USER        nobody
ENTRYPOINT  [ "/bin/node_exporter" ]
