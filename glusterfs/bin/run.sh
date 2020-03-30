#!/bin/bash
trap 'echo "Unexpected error";exit 1' ERR

export SSH_OPTS="-p ${SSH_PORT} -o ConnectTimeout=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
export GLUSTER_CONF_FLAG=/etc/gluster.env

[ "$DEBUG" == "1" ] && set -x && set +e

if [ n$1 == nbash ]; then
  echo "Starting shell"
  $*
  exit $?
fi

if [ "${ROOT_PASSWORD}" == "**ChangeMe**" -o -z "${ROOT_PASSWORD}" ]; then
   echo "*** ERROR: you need to define ROOT_PASSWORD environment variable - Exiting ..."
   exit 1
fi

if [ "${SERVICE_NAME}" == "**ChangeMe**" -o -z "${SERVICE_NAME}" ]; then
   echo "*** ERROR: you need to define SERVICE_NAME environment variable - Exiting ..."
   exit 1
fi

#Get my IP
export MY_IP=`ip addr show scope global |grep inet | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
export MY_NAME="$(hostname).${SERVICE_NAME}"
if [ -z "${MY_IP}" ]; then
   echo "*** ERROR: Could not determine this container's IP - Exiting ..."
   exit 1
fi

echo "root:${ROOT_PASSWORD}" | chpasswd

# Prepare a shell to initialize docker environment variables for ssh
echo "#!/bin/bash" > ${GLUSTER_CONF_FLAG}
echo "ROOT_PASSWORD=\"${ROOT_PASSWORD}\"" >> ${GLUSTER_CONF_FLAG}
echo "SSH_PORT=\"${SSH_PORT}\"" >> ${GLUSTER_CONF_FLAG}
echo "SSH_USER=\"${SSH_USER}\"" >> ${GLUSTER_CONF_FLAG}
echo "SSH_OPTS=\"${SSH_OPTS}\"" >> ${GLUSTER_CONF_FLAG}
echo "GLUSTER_VOLUMES=\"${GLUSTER_VOLUMES}\"" >> ${GLUSTER_CONF_FLAG}
echo "GLUSTER_VOL_OPTS=\"${GLUSTER_VOL_OPTS}\"" >> ${GLUSTER_CONF_FLAG}
echo "GLUSTER_ALL_VOLS_OPTS=\"${GLUSTER_ALL_VOLS_OPTS}\"" >> ${GLUSTER_CONF_FLAG}
echo "GLUSTER_BRICK_PATH=\"${GLUSTER_BRICK_PATH}\"" >> ${GLUSTER_CONF_FLAG}
echo "DEBUG=\"${DEBUG}\"" >> ${GLUSTER_CONF_FLAG}
echo "MY_IP=\"${MY_IP}\"" >> ${GLUSTER_CONF_FLAG}
echo "MY_NAME=\"${MY_NAME}\"" >> ${GLUSTER_CONF_FLAG}
echo "SERVICE_NAME=\"${SERVICE_NAME}\"" >> ${GLUSTER_CONF_FLAG}
echo "GLUSTER_DEBUG=\"${GLUSTER_DEBUG}\"" >> ${GLUSTER_CONF_FLAG}

perl -p -i -e "s/^Port .*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
perl -p -i -e "s/#?PasswordAuthentication .*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
perl -p -i -e "s/#?PermitRootLogin .*/PermitRootLogin yes/g" /etc/ssh/sshd_config
grep ClientAliveInterval /etc/ssh/sshd_config >/dev/null 2>&1 || echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config

join-gluster.sh &
exec /usr/bin/supervisord
