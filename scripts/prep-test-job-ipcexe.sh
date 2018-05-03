#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

read_app_ini ${INIFILE}

log "Copying application bundle $APP_ID into place"
cp -R $APP_ID/* ${TEMP_JOB_DIR}

log "Creating ipcexe and .agave.archive for $APP_ID"
python $DIR/prep-test-job-ipcexe.py tests/job-${APP_ID}.json $APP_ID/runner-template.sh ${TEMP_JOB_DIR}/local.ipcexe

