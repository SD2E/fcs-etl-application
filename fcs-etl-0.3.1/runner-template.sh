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
LOCAL_DATA_DIR=data

# DEBUG
echo "cytometerConfiguration: ${cytometerConfiguration}" >> inputs.txt
echo "processControl: ${processControl}" >> inputs.txt
echo "experimentalData: ${experimentalData}" >> inputs.txt
echo "colorModelParameters: ${colorModelParameters}" >> inputs.txt
echo "analysisParameters: ${analysisParameters}" >> input.txt
echo "inputData: ${inputData}" >> input.txt
echo "dummyInput: ${dummyInput}" >> input.txt

OWD=$PWD
# Predicted directory. Saem as inputData if not archive
inputDir=$(basename "${inputData}" .zip)

# Double check existence of inputData
if [ ! -e "${inputData}" ];
then
    die "inputData ${inputData} not found or accesible"
fi

# is inputData a zip archive?
# If so, unzip it, ignoring MacOSX line noise
if [[ "${inputData}" == *.zip ]]
then
    unzip -q -o ${inputData} -x "*.DS_Store" "*__MACOSX*" -d "${LOCAL_DATA_DIR}" && rm -rf ${inputData} || die "Error unzipping/removing $inputData"
else
    # Rename inputDir to data or whatever we want to call it
    if [ -d "${inputDir}" ]
    then
        mv -f "${inputDir}" "${LOCAL_DATA_DIR}"
    fi
fi

# Add contents of some child directories to .agave.archive
# Why? Because we don't need to copy the assay and controls
# back out at the end. 
# Agave uses .agave.archive to mark files that were present 
# before the core application logic began running. It's 
# generated automatically when the dependencies are staged
# into place on the executionHost and we're just extending
# that process a bit
for FN in assay controls
do
    echo "${LOCAL_DATA_DIR}/${FN}" >> .agave.archive
done


# Remove residual hard-coded /data/ paths from fc.json
# as they're just an artifact of early containerization
# efforts and are completely deprecated
# if [ -f "${fcFilename}" ];
# then
#     sed -e 's/\/data\//.\//g' -i'.bak' "${fcFilename}" || die "Error correcting paths in ${fcFilename}"
# else
#     die "Could not find or access ${fcFilename}"
# fi

# Do more validation on fc.json
# Noop for now - assume it's fine

# We have not failed yet. Systems are probably nominal.
# Kick off the analysis
container_exec ${CONTAINER_IMAGE} python /src/fcs.py --cytometer-configuration "${cytometerConfiguration}" --process-control "${processControl}"  --experimental-data "${experimentalData}" --color-model-parameters "${colorModelParameters}" --analysis-parameters "${analysisParameters}"
