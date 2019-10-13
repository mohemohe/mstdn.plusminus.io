#!/bin/bash

set -x

for NODE in $(docker node ls -q); do
  SSH_ADDR="$(docker node inspect "${NODE}" | jq -r '.[0].Status.Addr')"
  CONTAINER_ID="$(ssh "${SSH_ADDR}" docker ps -f 'name=mastodon_web' -q | head -1)"
  if [ "${CONTAINER_ID}" != "" ]; then
    ssh -tt "${SSH_ADDR}" docker exec -it "${CONTAINER_ID}" /bin/bash $*
    exit $?
  fi
done
