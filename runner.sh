#!/bin/bash

## Determine the path to currently executing script
## TODO: Find a way to not to require the cd in front of `source` part
## of the script
runner_self=`pwd`/`basename ${0}`
runner_default_task="default"

## Trap EXIT signal to bootstrap the runner.
## Works like a charm - your script ends, tasks start to run.
## Trap resets after bootstrapping.
trap '[[ ${?} -eq 0 ]] && runner_bootstrap' EXIT

## Split arguments into tasks and flags.
## All flags are then passed on to tasks.
## E.g. --production
for arg in ${@}; do
    if [[ ${arg} == -* ]]; then
        runner_flags="${runner_flags} ${arg}"
    else
        runner_tasks="${runner_tasks} ${arg}"
    fi
done

## Logs a message with a timestamp
runner_log() {
    local date=`date +%T.%N`
    echo [`runner_colorize "${date:0:12}" gray`] "${@}"
}

runner_log_error() {
    local date=`date +%T.%N`
    echo [`runner_colorize "${date:0:12}" gray`] \
        `runner_colorize "${@}" red`
}

## Returns unix time in ms
runner_time() {
    echo $((`date +%s%N` / 1000000))
}

## Returns a human readable duration in ms
runner_pretty_ms() {
    local ms=${1}
    local result
    ## If zero or nothing
    if [[ -z ${ms} || ${ms} -lt 1 ]]; then
        echo 0 ms
        return
    ## Only ms
    elif [[ ${ms} -lt 1000 ]]; then
        echo ${ms} ms
        return
    ## Only seconds with trimmed ms point
    elif [[ ${ms} -lt 60000 ]]; then
        result=$((ms / 1000 % 60)).$((ms % 1000))
        echo ${result:0:4} s
        return
    fi
    local parsed
    ## Days
    parsed=$((ms / 86400000))
    [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} d"
    ## Hours
    parsed=$((ms / 3600000 % 24))
    [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} h"
    ## Minutes
    parsed=$((ms / 60000 % 60))
    [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} m"
    ## Seconds
    parsed=$((ms / 1000 % 60))
    [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} s"
    ## Output result
    echo ${result}
}

runner_colorize() {
    case ${2} in
        black)        echo -en "\e[30m" ;;
        red)          echo -en "\e[31m" ;;
        green)        echo -en "\e[32m" ;;
        brown)        echo -en "\e[33m" ;;
        blue)         echo -en "\e[34m" ;;
        purple)       echo -en "\e[35m" ;;
        cyan)         echo -en "\e[36m" ;;
        light_gray)   echo -en "\e[37m" ;;
        gray)         echo -en "\e[90m" ;;
        light_red)    echo -en "\e[91m" ;;
        light_green)  echo -en "\e[92m" ;;
        light_brown)  echo -en "\e[93m" ;;
        light_blue)   echo -en "\e[94m" ;;
        light_purple) echo -en "\e[95m" ;;
        light_cyan)   echo -en "\e[96m" ;;
        white)        echo -en "\e[97m" ;;
        reset)        echo -en "\e[0m" ;;
    esac
    echo -e "${1}\e[0m"
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
        runner_log "  `runner_colorize ${task} cyan`"
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
            runner_log_error "Task '${task}' is not defined!"
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
    runner_log "Starting '`runner_colorize "${1}" cyan`'"
    local time_start=`runner_time`
    task_${1} ${runner_flags}
    local exit_code=${?}
    local time_end=`runner_time`
    local time_diff=`runner_pretty_ms $((time_end - time_start))`
    runner_log "Finished '`runner_colorize "${1}" cyan`'" \
        "after `runner_colorize "${time_diff}" purple`" \
        "(${exit_code})"
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
    echo ${@} | xargs -n1 -P0 bash ${runner_self} ${runner_flags}
}

## Bubble up non-zero exit-codes
runner_bubble() {
    if [[ ${1} -ne 0 ]]; then
        runner_log_error "Task '${runner_current_task}' bubbled with exit code ${1}."
        ## Exit with 255 to break parallel execution in `xargs`
        if [[ -n ${runner_break_parallel} ]]; then
            runner_log_error "Stopping parallel execution..."
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
