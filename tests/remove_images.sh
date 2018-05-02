#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

read_app_ini app.ini

docker rmi -f ${CONTAINER_IMAGE}
