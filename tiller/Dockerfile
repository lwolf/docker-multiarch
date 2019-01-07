ARG target

FROM $target/alpine:3.8

RUN apk update && apk add ca-certificates socat && rm -rf /var/cache/apk/*

ENV HOME /tmp

COPY helm /bin/helm
COPY tiller /bin/tiller

EXPOSE 44134
USER nobody
ENTRYPOINT ["/bin/tiller"]