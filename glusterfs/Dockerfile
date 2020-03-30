ARG target=ubuntu:20.04

FROM $target

ARG qemu_arch

# Metadata
LABEL org.label-schema.name="glusterfa" \
      org.label-schema.url="https://hub.docker.com/r/lwolf/glusterfa" \
      org.label-schema.vcs-url="https://github.com/lwolf/docker-multiarch"

COPY qemu-$qemu_arch-static /usr/bin/

RUN apt-get update && \
    apt-get install software-properties-common -y && \
    add-apt-repository ppa:gluster/glusterfs-7 -y && \
    apt-get update && \
    apt-get install -y glusterfs-server    \
                       iproute2            \
                       supervisor          \
                       openssh-server  \
                       dnsutils sshpass && \
    apt-get -y clean all

ENV ROOT_PASSWORD="**ChangeMe**" \
    SSH_PORT=2222 \
    SSH_USER=root \
    GLUSTER_VOLUMES=vol \
    GLUSTER_VOL_OPTS="" \
    GLUSTER_ALL_VOLS_OPTS="" \
    GLUSTER_BRICK_PATH=/gluster_volume \
    SERVICE_NAME=gluster \
    DEBUG=0

VOLUME ["${GLUSTER_BRICK_PATH}"]

RUN mkdir -p /var/run/sshd /root/.ssh /var/log/supervisor /usr/local/bin

ADD ./bin /usr/local/bin
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/usr/local/bin/run.sh"]
