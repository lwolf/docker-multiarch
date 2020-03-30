#!/bin/bash

# Exit status = 0 means the peer was successfully joined
# Exit status = 1 means there was an error while joining the peer to the cluster

trap 'echo "Unexpected error";rm -f /tmp/adding-gluster-node; exit 1' ERR

PEER_NAME=$1
PEER_IP=$2
PEER=$PEER_IP

if [ -z "${PEER_NAME}" ]; then
   echo "=> ERROR: I was supposed to add a new gluster peer to the cluster but no peer name was specified, doing nothing ..."
   exit 1
fi

if [ -z "${PEER_IP}" ]; then
   echo "=> ERROR: I was supposed to add a new gluster peer to the cluster but no peer IP was specified, doing nothing ..."
   exit 1
fi

#Since the remote peer is not ready we need to use /etc/hosts to resolve the IP
echo "$PEER_IP $PEER_NAME">>/etc/hosts

GLUSTER_CONF_FLAG=/etc/gluster.env
SEMAPHORE_FILE=/tmp/adding-gluster-node
SEMAPHORE_TIMEOUT=120
source ${GLUSTER_CONF_FLAG}

function log() {
  echo $(basename $0): [Running on $(hostname) - ${MY_IP}] $1
}

function detach() {
   log "=> Some error ocurred while trying to add peer ${PEER_NAME} to the cluster - detaching it ..."
   gluster peer detach ${PEER} force
   rm -f ${SEMAPHORE_FILE}
   exit 1
}

function status4peer() {
   echo `gluster peer status | grep -A2 "Hostname: $1" | grep State: | awk -F: '{print $2}'`
}

function getReplicas4Volume() {
  local NUMBER_OF_REPLICAS=`gluster volume info ${volume} | grep "Number of Bricks:" | awk '{print $6}'`
  if [ -z "${NUMBER_OF_REPLICAS}" ]; then
    #Less than 2 replicas
    NUMBER_OF_REPLICAS=`gluster volume info ${volume} | grep "Number of Bricks:" | awk '{print $4}'`
  fi
  echo $NUMBER_OF_REPLICAS
}

[ "$DEBUG" == "1" ] && set -x && set +e

log "=> Checking if I can reach gluster container ${PEER_NAME} and IP $PEER_IP ..."
if sshpass -p ${ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "hostname" >/dev/null 2>&1; then
   log "=> Gluster container ${PEER} is alive"
else
   log "*** Could not reach gluster container ${PEER} - exiting ..."
   exit 1
fi

if gluster peer status | grep ${PEER} &>/dev/null; then
  if echo "${PEER_STATUS}" | grep "Peer in Cluster"; then
    log "peer already added -> end"
    exit 0
  fi
fi

# Gluster does not like to add two nodes at once
for ((SEMAPHORE_RETRY=0; SEMAPHORE_RETRY<SEMAPHORE_TIMEOUT; SEMAPHORE_RETRY++)); do
   if [ ! -e ${SEMAPHORE_FILE} ]; then
      break
   fi
   log "*** There is another container joining the cluster, waiting $((SEMAPHORE_TIMEOUT-SEMAPHORE_RETRY)) seconds ..."
   sleep 1
done

if [ -e ${SEMAPHORE_FILE} ]; then
   log "*** Error: another container is joining the cluster"
   log "and after waiting ${SEMAPHORE_TIMEOUT} seconds I could not join peer ${PEER_NAME}, giving it up ..."
   exit 1
fi

#Lock
echo -n ${PEER_NAME}>${SEMAPHORE_FILE}


# Check if there are rejected peers (for example due to a re-connect with a different IP)
for volume in $GLUSTER_VOLUMES; do
  for brick in "${PEER}:${GLUSTER_BRICK_PATH}/${volume}" $(gluster volume info ${volume}| grep ":${GLUSTER_BRICK_PATH}/${volume}$"| awk '{print $2}'); do
    if ! gluster volume status ${volume}| grep -q ${brick}; then
      log "Removing brick ${brick} ..."
      NUMBER_OF_REPLICAS=`getReplicas4Volume ${volume}`
      if [ "$NUMBER_OF_REPLICAS" -lt "1" ]; then
        NUMBER_OF_REPLICAS=1
      fi
      if gluster --mode=script volume remove-brick ${volume} replica $((NUMBER_OF_REPLICAS-1)) ${brick} force; then
        log "Removed ${brick} successfully"
        #sleep 1
      fi
    fi
  done
done

# Remove the peer
if gluster peer detach ${PEER} force; then
  log "Detached ${PEER} successfully"
fi

# Probe the peer
PEER_STATUS=`status4peer ${PEER}`
if ! echo "${PEER_STATUS}" | grep "Peer in Cluster" >/dev/null; then
    # Peer probe
    log "=> Probing peer ${PEER} ..."
    gluster peer probe ${PEER}
    while gluster peer status | grep -A2 "Hostname: ${PEER}" | tail -n1 | grep -qv Connected; do
      log "Waiting for ${PEER}"
      sleep 1
    done
    sleep 1
    PEER_STATUS=`status4peer ${PEER}`
    log "=> Status for ${PEER} is ${PEER_STATUS}"
fi

for volume in $GLUSTER_VOLUMES; do

  log "PROCESING VOLUME $volume"

	# Create the volume
	if ! gluster volume list | grep "^${volume}$" >/dev/null; then
	   log "=> Creating GlusterFS volume ${volume}..."
	   gluster volume create ${volume} replica 2 ${MY_IP}:${GLUSTER_BRICK_PATH}/${volume} ${PEER}:${GLUSTER_BRICK_PATH}/${volume} force || detach
     if [ -n "${GLUSTER_VOL_OPTS}" ]; then
       log "=> Setting volume options: ${GLUSTER_VOL_OPTS}"
       gluster volume set ${volume} ${GLUSTER_VOL_OPTS}
     fi
     if [ -n "${GLUSTER_ALL_VOLS_OPTS}" ]; then
       log "=> Setting global volume options: ${GLUSTER_ALL_VOLS_OPTS}"
       gluster volume set all ${GLUSTER_ALL_VOLS_OPTS}
     fi
     #sleep 1
	fi

	# Start the volume
	if ! gluster volume status ${volume} >/dev/null; then
	   log "=> Starting GlusterFS volume ${volume}..."
	   gluster volume start ${volume}
	   #sleep 1
	fi

  # Check how many peers are already joined in the cluster - needed to add a replica
	NUMBER_OF_REPLICAS=`getReplicas4Volume ${volume}`
	if ! gluster volume info ${volume} | grep ": ${PEER}:${GLUSTER_BRICK_PATH}/${volume}$" >/dev/null; then
	   log "=> Adding brick ${PEER}:${GLUSTER_BRICK_PATH}/${volume} to the cluster (replica=$((NUMBER_OF_REPLICAS+1)))..."
	   gluster volume add-brick ${volume} replica $((NUMBER_OF_REPLICAS+1)) ${PEER}:${GLUSTER_BRICK_PATH}/${volume} force || detach
	fi

done

rm -f ${SEMAPHORE_FILE}
exit 0
