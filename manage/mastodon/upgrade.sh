#!/bin/bash

MAX_RETRY=30
RETRY_WAIT=10
MASTODON_DIR=../../swarm/mastodon
STACK_NAME=mastodon
SERVICE_NAME=web

function println() {
  echo -e "\033[0;36m$*\033[0;39m"
}

cd "${MASTODON_DIR}"

set -x

IMAGE_HASH=""

for NODE in $(docker node ls -q); do
  SSH_ADDR="$(docker node inspect "${NODE}" | jq -r '.[0].Status.Addr')"
  CONTAINER_IDS="$(ssh "${SSH_ADDR}" docker ps -f "name=${STACK_NAME}_${SERVICE_NAME}" -q)"
  if [ "${CONTAINER_IDS}" != "" ]; then
    for CONTAINER_ID in ${CONTAINER_IDS}; do
      image_hash=$(ssh "${SSH_ADDR}" docker inspect "${CONTAINER_ID}" | jq -r '.[0].Image')
      if [ "${IMAGE_HASH}" == "" ]; then
        IMAGE_HASH="${image_hash}"
      elif [ "${IMAGE_HASH}" != "${image_hash}" ]; then
        println "claster state not stable."
        exit 1
      fi
    done
  fi
done

println current image hash: "${IMAGE_HASH}"

docker stack deploy --compose-file docker-compose.yml "${STACK_NAME}"
DEPLOY_STATUS="$?"
if [ "${DEPLOY_STATUS}" != "0" ]; then
  println deploy error.
  exit "${DEPLOY_STATUS}"
fi

for i in $(seq 1 "$((MAX_RETRY+1))"); do
  println "wait ${RETRY_WAIT} sec."
  sleep "${RETRY_WAIT}"
  for NODE in $(docker node ls -q); do
    SSH_ADDR="$(docker node inspect "${NODE}" | jq -r '.[0].Status.Addr')"
    CONTAINER_IDS="$(ssh "${SSH_ADDR}" docker ps -f "name=${STACK_NAME}_${SERVICE_NAME}" -q)"
    if [ "${CONTAINER_IDS}" != "" ]; then
      for CONTAINER_ID in ${CONTAINER_IDS}; do
        image_hash=$(ssh "${SSH_ADDR}" docker inspect "${CONTAINER_ID}" | jq -r '.[0].Image')
        if [ "${IMAGE_HASH}" != "${image_hash}" ]; then
          ssh "${SSH_ADDR}" docker exec -i "${CONTAINER_ID}" /usr/bin/env rails db:migrate
          MIGRATE_STATUS="$?"
          if [ "$MIGRATE_STATUS" == "0" ]; then
            println db:migrate success.
            exit 0
          fi
        fi
      done
    fi
  done
  if [ "${i}" -le "${MAX_RETRY}" ]; then
    println seems not deployed. retry "${i}/${MAX_RETRY}"
  fi
done

println seems not deployed.
exit 1
