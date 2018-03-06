FROM sd2e/fcs-etl:build

ARG OCTAVE_VERSION=4.2.1-2~octave~xenial1
ARG TASBE_REPO=https://github.com/TASBE/TASBEFlowAnalytics.git
ARG TASBE_TAG=4.0.0
ARG TASBE_BRANCH=master

RUN cd / && \
    git clone  -b $TASBE_BRANCH $TASBE_REPO && \
    cd /TASBEFlowAnalytics && \
    git checkout tags/$TASBE_TAG &&\
    make install && \
    octave --eval 'pkg install -forge io'

# Local source code rather than Github
# Put this last so we can develop locally without cache-busting
ADD src /src

ADD config.yml /config.yml

CMD python /src/fcs.py --cytometer-configuration $CYT_CONFIG --process-control $PROC_CONTROL --experimental-data $EXP_DATA --color-model-parameters $COLOR_MODEL_PARAMS --analysis-parameters $ANALYSIS_PARAMS
