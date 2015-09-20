#!/bin/bash

declare -a runner_file_default_names=(
    'runnerfile.sh'
    'Runnerfile.sh'
    'runnerfile'
    'Runnerfile'
)

## Find a runnerfile.sh
for file in ${runner_file_default_names[*]}; do
    if [[ -f ${file} ]]; then
        runner_file=${file}
        source ${file}
        break
    fi
done

if [[ -z ${runner_file} ]]; then
    runner_log_error 'No runnerfile found.'
fi
