ARG target

FROM $target/alpine:3.8

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="matchbox" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/matchbox" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apk update \
    && apk add ca-certificates socat \
    && rm -rf /var/cache/apk/* \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

COPY matchbox /matchbox
EXPOSE 8080
USER        nobody
ENTRYPOINT ["/matchbox"]