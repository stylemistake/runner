#!/bin/bash

## Determine the path to currently executing script
## TODO: Find a way to not to require the cd in front of `source` part
## of the script
runner_self=`pwd`/`basename ${0}`
runner_default_task="default"
runner_current_task=""
runner_tasks=""
runner_args=""

## Trap EXIT signal to bootstrap the runner.
## Works like a charm - your script ends, tasks start to run.
## Trap resets after bootstrapping.
trap "[[ ${?} -eq 0 ]] && runner_bootstrap" EXIT

## Determine current task passed to script
## It searches for the first non-flag argument and sets it as a current task.
## All other arguments get filtered into `runner_args`
## TODO: Not implemented yet
runner_tasks="${@}"
# for arg in ${@}; do
#     if [[ -z ${runner_current_task} ]]; then
#         runner_current_task="${arg}"
#     else
#         runner_args="${runner_args} ${arg}"
#     fi
# done

runner_log() {
    local date=`date +%T.%N`
    echo "[${date:0:12}] ${@}"
}

## List all defined functions beginning with `task_`
runner_get_defined_tasks() {
    for task in `typeset -F | grep -o '\stask_[A-Za-z0-9_-]*'`; do
        echo ${task:5}
    done
}

## Fancy wrapper for `runner_get_defined_tasks`
runner_show_defined_tasks() {
    runner_log "Available tasks:"
    for task in `runner_get_defined_tasks`; do
        runner_log "  ${task}"
    done
}

## Checks if a program is accessible from current $PATH
runner_is_defined() {
    hash ${@} 2>/dev/null
    return ${?}
}

runner_is_task_defined() {
    for task in ${@}; do
        if ! runner_is_defined task_${task}; then
            return 1
        fi
    done
    return 0
}

runner_is_task_defined_verbose() {
    for task in ${@}; do
        if ! runner_is_defined task_${task}; then
            runner_log "Error: Task '${task}' is not defined!"
            runner_show_defined_tasks
            return 1
        fi
    done
    return 0
}

runner_set_default_task() {
    runner_default_task=${1}
}

## Export a variable to change the behaviour of `runner_bubble`
## which breaks execution of `xargs` on non-zero exits.
runner_break_parallel() {
    export runner_break_parallel=1
}

runner_run_task() {
    runner_current_task=${1}
    runner_log "Starting '${1}'"
    task_${1}
    local exit_code=${?}
    runner_log "Finished '${1}' (${exit_code})"
    return ${exit_code}
}

## Run tasks sequentially.
runner_sequence() {
    runner_is_task_defined_verbose ${@} || return 1
    for task in ${@}; do
        runner_run_task ${task} || return ${?}
    done
}

## Run tasks in parallel.
## Works by launching script itself with `xargs`
runner_parallel() {
    runner_is_task_defined_verbose ${@} || return 1
    echo ${@} | xargs -n1 -P0 bash ${runner_self}
}

## Bubble up non-zero exit-codes
runner_bubble() {
    if [ ${1} -ne 0 ]; then
        runner_log "Error: Task '${runner_current_task}' bubbled with exit code ${1}."
        ## Exit with 255 to break parallel execution in `xargs`
        if [[ -n ${runner_break_parallel} ]]; then
            runner_log "Stopping parallel execution..."
            exit 255
        else
            exit ${1}
        fi
    fi
}

## Starts the initial task.
runner_bootstrap() {
    ## Clear a trap we set up earlier
    trap - EXIT
    ## Run tasks
    if [[ -n ${runner_tasks} ]]; then
        runner_sequence ${runner_tasks}
        exit ${?}
    fi
    if runner_is_task_defined ${runner_default_task}; then
        runner_run_task ${runner_default_task}
        exit ${?}
    fi
    runner_log "Nothing to run."
    runner_show_defined_tasks
}
