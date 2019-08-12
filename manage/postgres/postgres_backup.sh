#!/bin/bash

set -x

DATE="$(date +%Y/%m/%d)"
TARGET_PATH="/backup/mastodon/postgres/${DATE}"
FILENAME="dump.$(date +%Y%m%d_%H%M%S).sql.zst"

for NODE in $(docker node ls -q); do
  SSH_ADDR="$(docker node inspect "${NODE}" | jq -r '.[0].Status.Addr')"
  CONTAINER_ID="$(ssh "${SSH_ADDR}" docker ps -f 'name=postgres_replica' -q)"
  if [ "${CONTAINER_ID}" != "" ]; then
    ssh "${SSH_ADDR}" docker exec -i "${CONTAINER_ID}" /usr/bin/env psql -c "'SELECT pg_wal_replay_pause();'" # 9.6は pg_xlog_replay_pause()
    ssh "${SSH_ADDR}" docker exec -i "${CONTAINER_ID}" /usr/bin/env pg_dumpall --verbose -f /var/tmp/dump.sql
    ssh "${SSH_ADDR}" docker exec -i "${CONTAINER_ID}" /usr/bin/env psql -c "'SELECT pg_wal_replay_resume();'" # 9.6は pg_xlog_replay_resume()
    ssh "${SSH_ADDR}" docker cp "${CONTAINER_ID}:/var/tmp/dump.sql" /var/tmp/dump.sql
    ssh "${SSH_ADDR}" docker exec -i "${CONTAINER_ID}" /usr/bin/env rm -f /var/tmp/dump.sql
    scp "${SSH_ADDR}:/var/tmp/dump.sql" /var/tmp/dump.sql
    ssh "${SSH_ADDR}" rm /var/tmp/dump.sql
    nice -n 19 zstd -1 /var/tmp/dump.sql -o "/var/tmp/${FILENAME}"
    mkdir -p "${TARGET_PATH}"
    cp "/var/tmp/${FILENAME}" "${TARGET_PATH}/${FILENAME}"
    rm -f "/var/tmp/${FILENAME}"
    exit 0
  fi
done

