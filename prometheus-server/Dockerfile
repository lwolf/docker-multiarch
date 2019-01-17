ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="prometheus" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/prometheus" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apk update \
    && apk add ca-certificates socat \
    && rm -rf /var/cache/apk/* \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

COPY prometheus                             /bin/prometheus
COPY promtool                               /bin/promtool
COPY prometheus.yml                         /etc/prometheus/prometheus.yml
COPY console_libraries/                     /usr/share/prometheus/console_libraries/
COPY consoles/                              /usr/share/prometheus/consoles/

RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
    mkdir -p /prometheus && \
    chown -R nobody:nogroup etc/prometheus /prometheus && \
    ln -s /prometheus /etc/prometheus/data

USER       nobody
EXPOSE     9090
VOLUME     [ "/prometheus" ]
WORKDIR    /etc/prometheus
ENTRYPOINT [ "/bin/prometheus" ]
