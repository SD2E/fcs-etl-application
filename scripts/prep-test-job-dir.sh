#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

JOBCACHE=".jobcache" && mkdir -p ${JOBCACHE}

read_app_ini ${INIFILE}
log "Preparing job directory for $APP_ID"

if [ -d "${TEMP_JOB_DIR}" ]; then
    rm -rf "${TEMP_JOB_DIR}"
fi

find ${JOBCACHE} -name "*$APP_ID" -exec cp -R {} ${TEMP_JOB_DIR} \;
