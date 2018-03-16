#!/bin/bash

JOBFILE=$1
TIMEOUT=1800

UNDER_CI=0
CI_PLATFORM=
CI_UID=$(id -u ${USER})
CI_GID=$(id -g ${USER})

function die(){
    echo "[ERROR]: $1"
}

function log(){
    echo "[INFO]: $1"
}

function file_exists_not_empty(){
    if [ ! -f $1 ]
    then
        die "$1 not present"
    elif [[ ! "$(wc -l $1 | awk '{print $1}')" -gt 0 ]]
    then
        die "$1 was empty"
    else
        log "$1 OK"
    fi
}

function detect_ci() {

  ## detect whether we're running under continous integration
  if [ ! -z "${TRAVIS}" ]; then
    if [ "${TRAVIS}" == "true" ]; then
      UNDER_CI=1
      CI_PLATFORM="Travis"
    fi
  fi

  if [ ! -z "${JENKINS_URL}" ]; then
    UNDER_CI=1
    CI_PLATFORM="Jenkins"
  fi

  if ((UNDER_CI)); then
    log "Continous integration detected ($CI_PLATFORM)"
  fi

}

## Begin script
# Are we under CI? 
detect_ci

# Maximum duration for any async task
if [ ! -z "${TIMEOUT}" ] && [ ${TIMEOUT} -ge 0 ]; then
    MAX_ELAPSED=$TIMEOUT
else
    MAX_ELAPSED=1000
fi 
INITIAL_PAUSE=5 # Initial delay
BACKOFF=2 # Exponential backoff

TS1=$(date "+%s")
TS2=
ELAPSED=0
PAUSE=${INITIAL_PAUSE}
JOB_STATUS=

JOB_ID=$(jobs-submit -v -F ${JOBFILE} | jq -r .id)
log "Job: ${JOB_ID}"

while [ "${JOB_STATUS}" != "FINISHED" ] || [ "${JOB_STATUS}" != "FAILED" ]
do
    TS2=$(date "+%s")
    ELAPSED=$((${TS2} - ${TS1}))
    JOB_STATUS=$(jobs-status -v ${JOB_ID} | jq -r .status)
    if [ "${ELAPSED}" -ge "${MAX_ELAPSED}" ]
    then
        break
    fi
    log "Waiting ${PAUSE} sec before polling again"
    sleep ${PAUSE}
    PAUSE=$(($PAUSE * $BACKOFF))
done

if [ "${JOB_STATUS}" == "FINISHED" ]
then
    log "Job completed in ${ELAPSED} sec"
    exit 0
else
    jobs-history -v ${JOB_ID}
    err "Job failed or timed out (> ${MAX_ELAPSED} sec)"
fi