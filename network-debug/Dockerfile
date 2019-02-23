ARG target

FROM $target/ubuntu

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="network-debugger" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/network-debugger" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apt-get update \
    && apt-get install -y iputils-ping dnsutils inetutils-traceroute traceroute dnstracer \
    && rm -Rf /usr/bin/qemu-$qemu_arch-static

ENTRYPOINT "/bin/bash"