#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

JOBCACHE=".jobcache" && mkdir -p ${JOBCACHE}

read_app_ini ${INIFILE}

function fetch_example_job_dir() {

    AGAVE_URI=$1
    DEST=$(basename "${AGAVE_URI}")

    log "Syncing ${AGAVE_URI} => ${DEST}"

    python scripts/agave_files_sync.py --recursive "${AGAVE_URI}" ${JOBCACHE}/

    # Error
    if [ "$?" == 0 ]; then
        log "Sync to $DEST was successful."
    else
        log "Possible sync error. Double check contents of ${JOBCACHE}/${DEST} before using."
    fi
}


while IFS=" " read -r uri
do
    if [[ ! $uri == \#* ]]; then
        fetch_example_job_dir $uri
    fi
done < "tests/url-${APP_ID}.txt"
