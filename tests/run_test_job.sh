#!/bin/bash

JOBFILE=$1
TIMEOUT=$2

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

log "RUn a test job"

# Are we under CI?
detect_ci

# Set maximum runtime, within tolerance
# affored by the sleep function we use 
# to implement exponential backoff
#
# Look first for passed value
MAX_ELAPSED=
if [ ! -z "${TIMEOUT}" ]; then
    MAX_ELAPSED=${TIMEOUT}
fi
# then, inherit from environment
if [ -z "${MAX_ELAPSED}" ]; then
    MAX_ELAPSED=${AGAVE_JOB_TIMEOUT}
fi
# then, fallback to 10 min
if [ -z "${MAX_ELAPSED}" ]; then
    MAX_ELAPSED=600
fi 

log "  Max duration: ~ ${MAX_ELAPSED} sec"

INITIAL_PAUSE=5 # Initial delay
BACKOFF=2 # Exponential backoff
TS1=$(date "+%s")
TS2=
ELAPSED=0
PAUSE=${INITIAL_PAUSE}
JOB_STATUS=

# submit the job and stash the id in a file to pick up by process
jobs-submit -v -F ${JOBFILE} > job-submitted.json
cat job-submitted.json
JOB_ID=$(jq -r .id job-submitted.json)
rm -f job-submitted.json

if [ -z "${JOB_ID}" ]; then
  die "Job submission failed"
fi
# if job file is deploy-sd2etest-job.json then
# id file == deploy-sd2etest-job.json.id
echo "${JOB_ID}" > "$(basename ${JOBFILE}).jobid"

log "  Job: ${JOB_ID}"

while [[ -z "${JOB_STATUS}" ]]
do
    TS2=$(date "+%s")
    ELAPSED=$((${TS2} - ${TS1}))
    JOB_STATUS=$(jobs-status -v ${JOB_ID} | jq -r .status | grep "FINISHED\|FAILED|STOPPED|KILLED|PAUSED" | grep -v "ARCHIVING" )
    if [ "${ELAPSED}" -ge "${MAX_ELAPSED}" ]
    then
        break
    fi
    log "  Waiting ${PAUSE} sec to poll again"
    sleep ${PAUSE}
    PAUSE=$(($PAUSE * $BACKOFF))
done

if [ "${JOB_STATUS}" == "FINISHED" ]
then
    log "Job completed. Runtime: ${ELAPSED} sec"
    exit 0
else
    jobs-history -v ${JOB_ID}
    die "Job failed/killed/timed-out. Runtime: ${ELAPSED} sec"
fi
