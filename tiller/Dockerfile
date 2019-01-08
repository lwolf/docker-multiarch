ARG target

FROM $target/alpine:3.8

# Metadata
LABEL org.label-schema.name="helm" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/helm" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

RUN apk update && apk add ca-certificates socat && rm -rf /var/cache/apk/*

ENV HOME /tmp

COPY helm /bin/helm
COPY tiller /bin/tiller

EXPOSE 44134
USER nobody
ENTRYPOINT ["/bin/tiller"]