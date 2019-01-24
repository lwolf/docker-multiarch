ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="blackbox_exporter" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/blackbox-exporter" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/
COPY blackbox_exporter  /bin/blackbox_exporter
COPY blackbox.yml       /etc/blackbox_exporter/config.yml

RUN apk update \
    && apk add ca-certificates socat \
    && rm -rf /var/cache/apk/* \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

EXPOSE      9115

ENTRYPOINT  [ "/bin/blackbox_exporter" ]
CMD         [ "--config.file=/etc/blackbox_exporter/config.yml" ]