#!/bin/bash

if [[ "${FUNCNAME[0]}" == source ]]; then
    runner_src_dir=`dirname $(readlink -f ${BASH_SOURCE[@]})`/src
    source ${runner_src_dir}/runner.sh
else
    echo "bash-task-runner: index.sh is for sourcing from other scripts."
fi
