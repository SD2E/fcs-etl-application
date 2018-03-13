#!/usr/bin/env bash

BC=$(command -v apps-build-container)
if [ -z "$BC" ]; then
    docker build -f Dockerfile -t fcs .
else
    apps-build-container --no-push $@
fi
