#!/bin/bash

set -x

for NODE in $(docker node ls -q); do
  SSH_ADDR="$(docker node inspect "${NODE}" | jq -r '.[0].Status.Addr')"
  CONTAINER_ID="$(ssh "${SSH_ADDR}" docker ps -f 'name=mastodon_web' -q | head -1)"
  if [ "${CONTAINER_ID}" != "" ]; then
    ssh "${SSH_ADDR}" docker exec -i "${CONTAINER_ID}" /usr/bin/env bundle exec bin/tootctl media remove $*
    exit $?
  fi
done
