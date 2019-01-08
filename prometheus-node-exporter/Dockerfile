ARG target

FROM $target/alpine:3.8

# Metadata
LABEL org.label-schema.name="node-exporter" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/node-exporter" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

RUN apk update && apk add ca-certificates socat && rm -rf /var/cache/apk/*

COPY node_exporter /bin/node_exporter

EXPOSE      9100
USER        nobody
ENTRYPOINT  [ "/bin/node_exporter" ]
