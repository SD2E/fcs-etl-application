#!/bin/bash

# this can be either a job.id file from run_test_job or just a job ID
JOBFILE=$1
# directory to download outputs to
DESTDIR=$2

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
# Are we under CI? 
log "Getting job outputs"

detect_ci

if [ -z "${DESTDIR}" ]; then
  DESTDIR=${AGAVE_JOB_GET_DIR}
  log "Got destination directory from AGAVE_JOB_GET_DIR: ${DESTDIR}"
fi
if [ -z "${DESTDIR}" ]; then
  DESTDIR="job_output"
  log "Using default destination directory: ${DESTDIR}"
fi

JOBIID=
if [ -f ${JOBFILE} ]; then
  JOBID=$(cat ${JOBFILE})
else
  JOBID=${JOBFILE}
fi

log "  Job ID: ${JOBID}"

# Remove previous or overlapping job output folders
if [ -d ${DESTDIR} ]; then
  rm -rf 
fi

jobs-output-get ${OPTS} -N ${DESTDIR} --recursive ${JOBID}

if [ -d ${DESTDIR} ]; then
  log "Got job outputs"
else
  die "Failed to get job outputs"
fi
