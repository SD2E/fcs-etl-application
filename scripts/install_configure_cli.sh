#!/usr/bin/env bash

# Requirements
#
# _AGAVE_USERNAME
# _AGAVE_PASSWORD
# _AGAVE_APIKEY
# _AGAVE_APISECRET
# _AGAVE_TENANT

curl -skL -O https://github.com/SD2E/sd2e-cli/raw/ci/sd2e-cloud-cli.tgz && \
  mv sd2e-cloud-cli.tgz $HOME/ && \
  cd $HOME && \
  tar zxvf sd2e-cloud-cli.tgz && \
  echo "export PATH=\$PATH:$HOME/sd2e-cloud-cli/bin" >> $HOME/.bashrc && \
  echo "export PATH=\$PATH:$HOME/sd2e-cloud-cli/bin" >> $HOME/.bash_profile

source ~/.bashrc
source ~/.bash_profile

echo "$HOME"
echo "$PATH"

pwd

ls -alth

tenants-init -t "${_AGAVE_TENANT}" && \
auth-tokens-create -S -u ${_AGAVE_USERNAME} -p ${_AGAVE_PASSWORD} -k ${_AGAVE_APIKEY} -s ${_AGAVE_APISECRET} && \
auth-check && \
profiles-list -v me

exit $?
