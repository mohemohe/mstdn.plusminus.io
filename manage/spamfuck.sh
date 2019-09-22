#!/bin/bash

#### require
# curl
# jq
# seq

#### config
# 最後に/を含めない
MASTODON_BASE_URL=https://mstdn.plusminus.io
# 開発ページで適当に発行する　read admin:read admin:write が必要
MASTODON_ADMIN_ACCESS_TOKEN=
# ユーザー名
BASE_USERNAME=Naomii
# 対象ドメイン
TARGET_DOMAIN=pawoo.net
# 検索下限
LOWER_LIMIT=1
# 検索上限
UPPER_LIMIT=100
# ユーザーごとの待ち時間　リモートユーザーを取得するので相手サーバーに迷惑にならないような秒数にする　LibraHack事件では1秒でOKだったけど相手サーバーのさじ加減かなー
WAIT_SECOND=5

###################################################################################################

function _wait() {
    echo -n "wait" 1>&2
    for i in $(seq 1 "${1}"); do {
        sleep 1
        echo -n . 1>&2
    } done
    echo 1>&2
}

function fetchUser() {
    echo "fetch '@${BASE_USERNAME}${1}@${TARGET_DOMAIN}'" 1>&2
    # GET /api/v1/admin/accounts にはresolveがないから一般向けの検索APIを使う
    curl -s -H "Authorization: Bearer ${MASTODON_ADMIN_ACCESS_TOKEN}" "${MASTODON_BASE_URL}/api/v2/search?q=@${BASE_USERNAME}${1}@${TARGET_DOMAIN}&resolve=true&limit=1" | jq '.accounts'
}

function checkUser() {
    echo "check '@${BASE_USERNAME}${1}@${TARGET_DOMAIN}'" 1>&2
    SUSPENDED="$(curl -s -H "Authorization: Bearer ${MASTODON_ADMIN_ACCESS_TOKEN}" "${MASTODON_BASE_URL}/api/v1/admin/accounts/${2}" | jq -r '.suspended')"
    if [[ "${SUSPENDED}" == "true" ]]; then {
        echo 1
    } else {
        echo 0
    } fi
}

function suspendUser() {
    echo "suspend '@${BASE_USERNAME}${1}@${TARGET_DOMAIN}'" 1>&2
    curl -X POST -s -H "Authorization: Bearer ${MASTODON_ADMIN_ACCESS_TOKEN}" -H 'content-type: application/x-www-form-urlencoded' --data 'type=suspend&report_id=&warning_preset_id=&text=suspend%20by%20spamfuck.sh&send_email_notification=false' "${MASTODON_BASE_URL}/api/v1/admin/accounts/${2}/action" | jq '.error'
}

for SUFFIX in $(seq ${LOWER_LIMIT} ${UPPER_LIMIT}); do {
    _wait ${WAIT_SECOND}
    ACCOUNTS="$(fetchUser "${SUFFIX}")"
    EXISTS="$(echo "${ACCOUNTS}" | jq length)"
    if [[ "${EXISTS}" != 1 ]]; then {
        echo not found. skip. 1>&2
        continue
    } fi
    ID="$(echo "${ACCOUNTS}" | jq -r .[0].id)"
    if [[ "$(checkUser "${SUFFIX}" "${ID}")" == "1" ]]; then {
        echo already syspended. skip. 1>&2
        continue
    } fi
    STATUS="$(suspendUser "${SUFFIX}" "${ID}")"
    if [[ "${STATUS}" == "null" ]]; then {
        echo 'suspend success.' 1>&2
    } else {
        echo 'suspend failed.' 1>&2
    } fi
} done