#!/bin/bash

CONTAINER_IMAGE=$1
JOBDIR=$2

UNDER_CI=0
CI_PLATFORM=
CI_UID=$(id -u ${USER})
CI_GID=$(id -g ${USER})

set -e

function die(){
    echo "[ERROR]: $1"
    exit 1
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

# Are we running under CI
detect_ci

# Tweak config for Docker depending on if we're running under CI
dockeropts=
if ((UNDER_CI)); then
  # If running a Dockerized process with a volume mount
  # written files will be owned by root and unwriteable by
  # the CI user. We resolve this by setting the group, which
  # is the same approach we use in the container runner 
  # that powers container-powered Agave jobs
  dockeropts=" --user=0:${CI_GID}"
fi

docker run ${dockeropts} -t -v ${PWD}/${JOBDIR}:/data ${CONTAINER_IMAGE} ls /data
docker run ${dockeropts} -t -v ${PWD}/${JOBDIR}:/data ${CONTAINER_IMAGE} python /src/test_scratch.py
docker run ${dockeropts} -t -v ${PWD}/${JOBDIR}:/data -w /data ${CONTAINER_IMAGE} python /src/fcs.py \
                         --cytometer-configuration=/data/cytometer_configuration.json \
                         --process-control=/data/process_control_data.json \
                         --experimental-data=/data/experimental_data.json \
                         --color-model-parameters=/data/color_model_parameters.json \
                         --analysis-parameters=/data/analysis_parameters.json
# Validate outputs
# Checking only for existence and non-emptiness here
# This should be a separate file so we can run it against 
# downloaded results from the Agave job
log "Verifying results..."
CSVS=$(cd ${JOBDIR} && ls output/*.csv )
log "Output CSV files:"
log "${CSVS}"

for FILE_TO_TEST in junit/TASBESession.xml ${CSVS}
do
    file_exists_not_empty ${JOBDIR}/${FILE_TO_TEST}
done

set +e
