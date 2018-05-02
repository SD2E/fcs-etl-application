INIFILE="app.ini"
DOCKER_HUB_ORG=
DOCKER_IMAGE_TAG=
DOCKER_IMAGE_VERSION=
CONTAINER_IMAGE=

UNDER_CI=0
CI_PLATFORM=
CI_UID=$(id -u ${USER})
CI_GID=$(id -g ${USER})

function die(){
    echo "[ERROR] $1"
    exit 1
}

function log(){
    echo "[INFO] $1"
}

function detect_ci() {

  ## detect whether we're running under continous integration
  if [ ! -z "${TRAVIS}" ]; then
    if [ "${TRAVIS}" == "true" ]; then
      UNDER_CI=1
      CI_PLATFORM="Travis"
      CI_UID=$(id -u travis)
      CI_GID=$(id -g travis)
    fi
  fi

  if [ ! -z "${JENKINS_URL}" ]; then
    UNDER_CI=1
    CI_PLATFORM="Jenkins"
    CI_UID=$(id -u jenkins)
    CI_GID=$(id -g jenkins)
  fi

  if ((UNDER_CI)); then
    log "Continuous integration detected ($CI_PLATFORM)"
  else
    log "Not running under continous integration"
  fi

}

function read_app_ini() {

    INIFILE=$1
    if [ -z "$INIFILE" ]; then
      INIFILE="app.ini"
    fi
    if [ ! -f "$INIFILE" ]; then
      die "Unable to find or access $INIFILE"
    fi

    export DOCKER_HUB_ORG=$(grep "username" $INIFILE | awk -F '=' '{ print $2 }' | tr -d " ")
    export DOCKER_IMAGE_TAG=$(grep "repo" $INIFILE | awk -F '=' '{ print $2 }' | tr -d " ")
    export DOCKER_IMAGE_VERSION=$(grep "tag" $INIFILE | awk -F '=' '{ print $2 }' | tr -d " ")

    CONTAINER_IMAGE="${DOCKER_IMAGE_TAG}"
    if [ ! -z "${DOCKER_HUB_ORG}" ]; then
      CONTAINER_IMAGE="${DOCKER_HUB_ORG}/${CONTAINER_IMAGE}"
    fi
    if [ ! -z "${DOCKER_IMAGE_VERSION}" ]; then
      CONTAINER_IMAGE="${CONTAINER_IMAGE}:${DOCKER_IMAGE_VERSION}"
    fi
    export CONTAINER_IMAGE

    echo "$INIFILE => $CONTAINER_IMAGE"

}
