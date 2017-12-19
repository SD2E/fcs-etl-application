FROM ubuntu:xenial
ARG OCTAVE_VERSION=4.2.1-2~octave~xenial1

ARG TASBE_REPO=https://github.com/TASBE/TASBEFlowAnalytics.git
ARG TASBE_BRANCH=jed_with_point_clouds

ARG REACTOR_REPO=https://github.com/SD2E/reactors-etl.git
ARG REACTOR_BRANCH=new-fcs-tasbe

RUN apt-get update
RUN apt-get install software-properties-common python-software-properties -y
RUN add-apt-repository ppa:octave/stable


RUN apt-get update && \
		apt-get install -y \
				x11-apps \
        wget \
        build-essential \
        cmake \
        bsdtar \
        curl \
        libcurl4-openssl-dev \
        gnuplot \
        gnuplot-data \
        gnuplot-tex \
        gnuplot-x11 \
        gperf \
        flex \
        bison \
        rsync \
        unzip \
        libfontconfig1-dev \
        libfontconfig1 \
        octave=$OCTAVE_VERSION \
        liboctave-dev \
        octave-info \
        python3-dev \
        pandoc \
        ttf-dejavu

RUN apt-get install default-jdk default-jdk-headless epstool gperf hdf5-helpers javahelper libaec-dev libarpack2-dev libblas-dev libbtf1.2.1 libcsparse3.1.4 libexif-dev libfftw3-dev libflac-dev libfltk-cairo1.3 libfltk-forms1.3 libfltk-images1.3 libfltk1.3-dev libftgl-dev libftgl2 libglpk-dev libgraphicsmagick++1-dev libgraphicsmagick1-dev libhdf5-cpp-11 libhdf5-dev libjack-dev libjasper-dev libklu1.3.3 liblapack-dev libldl2.2.1 libogg-dev libosmesa6-dev libportaudiocpp0 libqhull-dev libqrupdate-dev libqscintilla2-dev libqt4-designer libqt4-dev libqt4-dev-bin libqt4-help libqt4-opengl-dev libqt4-qt3support libqt4-scripttools libqt4-svg libqt4-test libsndfile1-dev libspqr2.0.2 libsuitesparse-dev libvorbis-dev libwmf-dev openjdk-8-jdk openjdk-8-jdk-headless portaudio19-dev qt4-linguist-tools qt4-qmake uuid-dev llvm-3.5-dev libpcre3-dev -y

RUN apt-get install git -y
RUN apt-get install python -y
RUN apt-get install python-pip -y
RUN pip install --upgrade pip
RUN pip install oct2py 
RUN pip install --upgrade --force-reinstall octave_kernel
RUN pip install jupyter
RUN apt-get install python-numpy -y
RUN apt-get install python-scipy -y

RUN cd / && git clone -b $REACTOR_BRANCH $REACTOR_REPO && \
    cd /reactors-etl && \
    cp -r /reactors-etl/reactors/fcs-tasbe/src /src


RUN cd / && \
    git clone $TASBE_REPO && \
    cd /TASBEFlowAnalytics && \
    git fetch && \
    git pull origin $TASBE_BRANCH && \
    git checkout $TASBE_BRANCH && \
    make install && \
    cd /TASBEFlowAnalytics/code && octave --eval 'addpath(genpath(pwd)); savepath;' &&\
    octave --eval 'pkg install -forge io'


#CMD python /src/fcs.py --cytometer-configuration $CYT_CONFIG --process-control $PROC_CONTROL --experimental-data $EXP_DATA --color-model-parameters $COLOR_MODEL_PARAMS --analysis-parameters $ANALYSIS_PARAMS
