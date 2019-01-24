ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="alertmanager" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/alertmanager" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/
COPY amtool                       /bin/amtool
COPY alertmanager                 /bin/alertmanager
COPY alertmanager.yml /etc/alertmanager/alertmanager.yml

RUN apk update \
    && apk add ca-certificates \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /alertmanager \
    && chown -R nobody:nogroup etc/alertmanager /alertmanager \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]