#!/bin/bash

declare -a runner_file_default_names=(
    'runnerfile.sh'
    'Runnerfile.sh'
    'runnerfile'
    'Runnerfile'
)

## Find a runnerfile
for file in "${runner_file_default_names[@]}"; do
    if [[ -f ${file} ]]; then
        runner_file="${file}"
        source "${file}"
        break
    fi
done

## Runnerfile not found
if [[ -z ${runner_file} ]]; then
    trap - EXIT
    runner_log_error 'No runnerfile found.'
    exit 2
fi
