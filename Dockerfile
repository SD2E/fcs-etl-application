# Intermediate image with octave + latest TASBE installed
FROM sd2e/tasbe-base:dev

# Add support for in-container testing using
# the requirements from sd2e/base-images/languages/python2
# https://github.com/SD2E/base-images/blob/master/languages/python2/requirements-edge.txt
ADD requirements-testing.txt /tmp/requirements.txt
RUN pip install --upgrade --no-cache -r /tmp/requirements.txt

# Local source code rather than Github
# Put this last so we can develop locally without cache-busting
ADD src /src

ADD config.yml /config.yml

CMD python /src/fcs.py --cytometer-configuration $CYT_CONFIG --process-control $PROC_CONTROL --experimental-data $EXP_DATA --color-model-parameters $COLOR_MODEL_PARAMS --analysis-parameters $ANALYSIS_PARAMS

