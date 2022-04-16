#!/usr/bin/env bash
# Copyright © 2019 Maestro Creativescape

ADMINS="@RealAkito @Stallix @Anierin_Bliss"
COMMIT_AUTHOR="$(git log -1 --format='%an <%ae>')"
COMMIT_MESSAGE="$(git log -1 --pretty=%B)"
COMMIT_SMALL_HASH="$(git rev-parse --short HEAD)"
COMMIT_HASH="$(git rev-parse --verify HEAD)"

function sendTG() {
    curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendmessage" --data "text=${*}&chat_id=-1001539241326&parse_mode=HTML"
}

printf "\n\n***Evolution X CI***\n\n"
BUILD_START=$(date +"%s")

if [ -n "$PULL_REQUEST_NUMBER" ]; then
    sendTG "\`I have recieved PR $PULL_REQUEST_NUMBER.\`"
else
    git checkout master  > /dev/null
    git pull origin master  > /dev/null
    sendTG "<b>I am starting to build!</b> %0A<b>Commit Point:</b> <a href='https://github.com/Evolution-X-Devices/official_devices/commit/${COMMIT_HASH}'>${COMMIT_SMALL_HASH}</a>"
fi

node json_tester.js

RESULT=$?

if [ -n "$PULL_REQUEST_NUMBER" ]; then

    if [ "$RESULT" -eq 1 ]; then
        sendTG "\`PR $PULL_REQUEST_NUMBER is failing checks. Maintainer is requested to check it\` %0A%0A<b>Failed File:</b> \`$(cat /tmp/failedfile)\` %0A%0A<a href='https://github.com/Evolution-X-Devices/official_devices/pull/$PULL_REQUEST_NUMBER'>PR Link</a>"
        exit 1
    else
        sendTG "\`PR $PULL_REQUEST_NUMBER can be merged.\` %0A%0A${ADMINS} %0A%0A<a href='https://github.com/Evolution-X-Devices/official_devices/pull/$PULL_REQUEST_NUMBER'>PR Link</a>"
        exit 0
    fi

fi

if [ "$RESULT" -eq 1 ]; then
    sendTG "\`Someone have merged broken file! Please take a look ASAP!\` %0A%0A${ADMINS} %0A%0A<b>Failed File:</b> \`$(cat /tmp/failedfile)\`"
    exit 1
fi

GIT_CHECK="$(git status | grep "modified")"

# Hack around some derps
if [[ ! "$COMMIT_MESSAGE" =~ "[EvolutionX-CI]" ]] && [ -n "$GIT_CHECK" ]; then
      git reset HEAD~1
    git add .
    git commit -m "[EvolutionX-CI]: ${COMMIT_MESSAGE}" --author="${COMMIT_AUTHOR}" --signoff
    git remote rm origin
    git remote add origin https://realakito:"${GH_PERSONAL_TOKEN}"@github.com/Evolution-X-Devices/official_devices.git
    git push -f origin master
    sendTG "JSON Linted and Force Pushed!"
fi
BUILD_END=$(date +"%s")
