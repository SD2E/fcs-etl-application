# Allow over-ride
if [ -z "${CONTAINER_IMAGE}" ]
then
    version=$(cat ./_util/VERSION)
    CONTAINER_IMAGE="sd2e/fcs:$version"
fi
. _util/container_exec.sh

log(){
    mesg "INFO" $@
}

die() {
    mesg "ERROR" $@
    # AGAVE_JOB_CALLBACK_FAILURE is macro populated at runtime
    # by the platform and gives us an eject button from
    # anywhere the application is running
    ${AGAVE_JOB_CALLBACK_FAILURE}
}

mesg() {
    lvl=$1
    shift
    message=$@
    echo "[$lvl] $(utc_date) - $message"
}

utc_date() {
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ")
}

#### BEGIN SCRIPT LOGIC
# Assumptions
#
# <inputData> can be a directory - agave://data-sd2e-community/sample/fcs-tasbe/Q0-ProtStab-BioFab-Flow_29092017
# <inputData> can be a compressed directory - agave://data-sd2e-community/sample/fcs-tasbe/Q0-ProtStab-BioFab-Flow_29092017.[zip|tgz]
# <inputData> contains assay, controls, output, plots, quicklook

# The various JSON files assume that, no matter what the original name of <inputData>, information needed for processing can 
# be found under the job-local ./data directory

# We may want to be able to pass this in as a parameter or detect it from the JSON files
# For now, just hardcode it
LOCAL_DATA_DIR="."

OWD=$PWD
# Predicted directory. Saem as inputData if not archive
inputDir=$(basename "${inputData}" .zip)

# if inputData is already instrument_output, do nothing
if [ "${inputDir}" != "instrument_output" ]
then
    if [ ! -d "instrument_output" ]
    then
        mv "${inputDir}" "instrument_output"
        echo "Renamed ${inputDir} to instrument_output"
        inputDir="instrument_output"
    else
        echo "${inputDir} != instrument_output but instrument_output already exists"
    fi
fi

# Double check existence of inputDir before undertaking
# expensive processing and/or analysis. Fail if not found. 
if [ ! -d "${inputDir}" ];
then
    die "inputData ${inputDir} not found or was inaccessible"
fi

# Add contents of some child directories to .agave.archive
# Why? Because we don't need to copy the assay and controls
# back out at the end. 
# Agave uses .agave.archive to mark files that were present 
# before the core application logic began running. It's 
# generated automatically when the dependencies are staged
# into place on the executionHost and we're just extending
# that process a bit
for FN in assay controls instrument_output manifest
do
    echo "${FN}" >> .agave.archive
    echo "octave-workspace" >> .agave.archive
done

# These files already exist in another place
# so we should not duplicate them in the output archive. 
for J in analysis_parameters color_model_parameters cytometer_configuration experimental_data process_control_data
do
    echo "${J}.json" >> .agave.archive
done

# We have not failed yet. Systems are probably nominal.
# Kick off the analysis
container_exec ${CONTAINER_IMAGE} python /src/fcs.py --cytometer-configuration "${cytometerConfiguration}" --process-control "${processControl}"  --experimental-data "${experimentalData}" --color-model-parameters "${colorModelParameters}" --analysis-parameters "${analysisParameters}"
