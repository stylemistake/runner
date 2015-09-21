#!/bin/bash

if [[ "${FUNCNAME[0]}" == source ]]; then
    if [[ -n ${TARGET_PATH} ]]; then
        ## Use path from bash-require
        runner_src_dir="${TARGET_PATH}/src"
    else
        ## Determine path from BASH_SOURCE variable
        runner_src_dir="`dirname $(readlink -f ${BASH_SOURCE[0]})`/src"
    fi
    source ${runner_src_dir}/runner.sh
else
    echo "bash-task-runner: index.sh is for sourcing from other scripts."
fi
