#!/bin/bash

trap '(echo "Unexpected error";kill -s SIGINT 1; exit 1' ERR

[ "$DEBUG" == "1" ] && set -x

function check_if_already_joined {
   # Check if I'm part of the cluster
   NUMBER_OF_PEERS=`gluster peer status | grep "Number of Peers:" | awk -F: '{print $2}'`
   if [ "${NUMBER_OF_PEERS}" -ne 0 ]; then
      # This container is already part of the cluster
      echo "=> This container is already joined with nodes ${GLUSTER_PEERS}, skipping joining ..."
      touch /IamReady
      exit 0
   fi
}

echo "=> Waiting for glusterd to start..."
until [ -e /var/run/glusterd.pid ]; do
  sleep 1
done
echo "... glusterd ready!"


# Join the cluster - choose a suitable container
ALIVE=0
while [ ${ALIVE} -eq 0 ]; do

  #Already joined?
  check_if_already_joined

  for PEER in `dig +short ${SERVICE_NAME}`; do

     # Skip myself
     if [ "${MY_IP}" == "${PEER}" ]; then
        continue
     fi
     echo "=> Checking if I can reach gluster container ${PEER} ..."
     if sshpass -p ${ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "hostname" >/dev/null 2>&1; then
        echo "=> Gluster container ${PEER} is alive"
        ALIVE=1
        break
     else
        echo "*** Could not reach gluster container ${PEER} ..."
     fi
  done

  if [ ${ALIVE} -eq 0 ]; then
    echo "Could not reach any GlusterFS container from this list: ${GLUSTER_PEERS}"
    echo "I am either the first one or ${PEER} is not completely up -> I will keep trying..."
    touch /IamReady
    sleep 1
  fi
done

# If PEER has requested me to join him, just wait for a while
# This happens when we are bootstrapping the cluster
SEMAPHORE_FILE=/tmp/adding-gluster-node.${PEER}
if grep ${PEER} ${SEMAPHORE_FILE}&>/dev/null; then
  echo "=> Seems like peer ${PEER} has just requested me to join him"
  echo "=> So I'm waiting for 20 seconds to finish it..."
  sleep 20
fi
check_if_already_joined

echo "=> Joining cluster with container ${PEER} ..."
if sshpass -p ${ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "add-gluster-peer.sh ${MY_NAME} ${MY_IP}"; then
  echo "=> Successfully joined cluster with container ${PEER} ..."
  touch /IamReady
else
  echo "=> Error joining cluster with container ${PEER} ..."
  check_if_already_joined
  if [ -z "${GLUSTER_DEBUG}" ]; then
    echo "=> Error joining cluster with container ${PEER} - terminating ..."
    kill -s SIGINT 1
  else
    echo "=> Error joining cluster with container ${PEER} - keeping it alive because env variable GLUSTER_DEBUG is not empty ..."
    touch /IamReady
  fi
fi
