#!/bin/bash

CONTAINER_IMAGE=$1
if [ -z "$CONTAINER_IMAGE" ]; then
  CONTAINER_IMAGE="sd2e/fcs:0.3.3"
fi

set -e

AGAVEURI=agave://data-sd2e-community/sample/fcs-tasbe/fcs-etl-reactor-example
JOBDIR=fcs-etl-reactor-example

function die(){
    echo "[ERROR]: $1"
}

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

log "Syncing data from $(basename $AGAVEURI)..."
python scripts/agave-files-sync.py -r ${AGAVEURI} .

docker run -t -v $PWD/$JOBDIR:/data fcs-etl ls /data
docker run -t -v $PWD/$JOBDIR:/data fcs-etl python /src/test_scratch.py
docker run -v $PWD/$JOBDIR:/data -w /data \
           -e "CYT_CONFIG=/data/cytometer_configuration.json" \
           -e "PROC_CONTROL=/data/process_control_data.json" \
           -e "EXP_DATA=/data/experimental_data.json" \
           -e "COLOR_MODEL_PARAMS=/data/color_model_parameters.json" \
           -e "ANALYSIS_PARAMS=/data/analysis_parameters.json" ${CONTAINER_IMAGE}

# Validate outputs
# Checking only for existence and non-emptiness here
log "Verifying results..."
CSVS=$(cd $JOBDIR && ls output/*.csv )
log "Output CSV files:"
log "$CSVS"

for FILE_TO_TEST in junit/TASBESession.xml $CSVS
do
    file_exists_not_empty $JOBDIR/$FILE_TO_TEST
done

set +e