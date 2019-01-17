ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="snmp-exporter" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/snmp-exporter" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apk update \
    && apk add ca-certificates socat \
    && rm -rf /var/cache/apk/* \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

ADD snmp.yml /etc/snmp_exporter/snmp.yml
COPY snmp_exporter  /bin/snmp_exporter

EXPOSE      9116
ENTRYPOINT  [ "/bin/snmp_exporter" ]
CMD         [ "--config.file=/etc/snmp_exporter/snmp.yml" ]
