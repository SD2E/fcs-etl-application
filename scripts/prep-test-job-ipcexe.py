#!/usr/bin/env python

from __future__ import print_function
import json
import os
import re
import sys


def write_header(dest):
    with open(dest, 'w') as ipcexe:
        ipcexe.write("""#!/usr/bin/env bash

##############################################################
# Debugging Support
##############################################################
set -e

##############################################################
# Agave Runtime IO Redirections
##############################################################

# Capture the PID of this job on the system for remote monitoring
echo $$ > local.pid

# Pause for 2 seconds to avoid a callback race condition
sleep 2

# Redirect STDERR and STDOUT to job output and error files
exec 2>local.err 1>local.out

##########################################################
# Agave Environment Settings
##########################################################

# Location of agave job lifecycle log file
AGAVE_LOG_FILE=.agave.log

##########################################################
# Agave Utility functions
##########################################################

# cross-plaltform function to print an ISO8601 formatted timestamp
function agave_datetime_iso() {
  date '+%Y-%m-%dT%H:%M:%S%z';
}

# standard logging function to write agave job lifecycle logs
function agave_log_response() {
  echo "[$(agave_datetime_iso)] ${@}";
} 2>&1 >> "${AGAVE_LOG_FILE}"

##########################################################
# Agave App and System Environment Settings
##########################################################

# No modules commands configured for this app

# No custom environment variables configured for this app

##########################################################
# Begin App Wrapper Template Logic
##########################################################
""")


def write_footer(dest):
    with open(dest, 'a') as ipcexe:
        ipcexe.write("""
##########################################################
# End App Wrapper Template Logic
##########################################################

set +e
""")


def write_agavearchive(dest, files):
    arch = os.path.join(os.path.dirname(dest), '.agave.archive')
    with open(arch, 'w') as archive:
        for l in files:
            archive.write('{}\n'.format(l))


if __name__ == "__main__":
    job = sys.argv[1]
    templ = sys.argv[2]
    dest = sys.argv[3]

    env = {}
    templdata = None
    regexes = {}
    noarchive = ['local.ipcexe']

    with open(job) as json_data:
        jj = json.load(json_data)

    # process inputs
    try:
        inputs = jj.get('inputs', {})
        if isinstance(inputs, dict):
            for (k, v) in list(inputs.items()):
                if isinstance(v, list):
                    v = v[0]
                elif isinstance(v, tuple):
                    v = v[0]
                else:
                    v = v
                v = os.path.basename(v)
                env[k] = v
                noarchive.append(v)
    except Exception as e:
        print("Error processing inputs: {}".format(e))
        pass

    # process parameters
    try:
        inputs = jj.get('parameters', {})
        if isinstance(inputs, dict):
            for (k, v) in list(inputs.items()):
                if isinstance(v, list):
                    v = v[0]
                elif isinstance(v, tuple):
                    v = v[0]
                env[k] = v

    except Exception as e:
        print("Error processing parameters: {}".format(e))
        pass

    # read the template
    with open(templ, 'r') as template:
        templdata = template.readlines()

    # compile regexes
    for (k, v) in env.items():
        pattern = r'\${\s?' + k + '\s?}'
        print("Pattern {}".format(pattern))
        regexes[k] = re.compile(pattern)

    # header
    write_header(dest)

    # tempate out ipcexe file
    with open(dest, 'a') as ipcexe:
        for line in templdata:
            for rx in list(regexes.keys()):
                line = re.sub(regexes[rx], env[rx], line)
            ipcexe.write(line)

    write_footer(dest)

    # write agave.archive file
    write_agavearchive(dest, noarchive)
