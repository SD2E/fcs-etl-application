#!/usr/bin/env bash

COMMANDS="$@"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"
source "$DIR/container_exec.sh"

AGAVE_USE_TMP=1

read_app_ini app.ini

# Inherited from REACTOR_RC
# TODO: Allow override by ENV
CONTAINER_IMAGE="$DOCKER_HUB_ORG/${DOCKER_IMAGE_TAG}:${DOCKER_IMAGE_VERSION}"

if [ -z "${CONTAINER_IMAGE}" ]; then
    echo "Usage: $(basename $0) <container_image>" &&
    exit 1
fi

# Emphemeral directory
#  Can be specified with AGAVE_JOB_DIR
#  Can be turned off with AGAVE_USE_TMP=0
WD=${PWD}
echo "AGAVE_JOB_DIR => ${AGAVE_JOB_DIR}"
if [ ! -z "${AGAVE_JOB_DIR}" ]; then
    mkdir -p "${AGAVE_JOB_DIR}"
    WD=${AGAVE_JOB_DIR}
else
    TEMP=`mktemp -d $PWD/tmp.XXXXXX`
    WD=${TEMP}
fi
echo "WD => $WD"

# # Because we're running pytest in a temp directory, copy setup.cfg there
# # to parameterize it. Otherwise, we get stock pytest behavior which is
# # not very useful
# if [ -f "setup.cfg" ]; then
#     cp setup.cfg $WD/
# fi

OWD=$PWD
cd $WD
container_exec ${CONTAINER_IMAGE} ${COMMANDS}
cd $PWD

if [ ! -z "${TEMP}" ]; then
    log "Cleaning up ${TEMP}"
    rm -rf ${TEMP}
fi
