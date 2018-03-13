#!/usr/bin/env bash


DEP=$(command -v apps-deploy)
if [ -z "$DEP" ]; then
    bash deploy.orig.sh $@
else
    apps-deploy $@
fi
