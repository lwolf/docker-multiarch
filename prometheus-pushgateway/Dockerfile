ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="pushgateway" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/pushgateway" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/
COPY pushgateway /bin/pushgateway

RUN apk update \
    && apk add ca-certificates \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /pushgateway \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

EXPOSE 9091
WORKDIR /pushgateway
ENTRYPOINT [ "/bin/pushgateway" ]