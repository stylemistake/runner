#!/bin/bash

## Default task (settable with `runner_set_default_task`)
runner_default_task="default"

## Trap EXIT signal to bootstrap the runner.
## Works like a charm - your script ends, tasks start to run.
## Trap resets after bootstrapping.
trap '[[ ${?} -eq 0 ]] && runner_bootstrap' EXIT

## Expand aliases
shopt -s expand_aliases

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
    echo [${runner_colors[gray]}${date:0:12}${runner_colors[reset]}] "${*}"
}

## Variations of log with colors
runner_log_error() {
    runner_log ${runner_colors[red]}"${*}"${runner_colors[reset]}
}

runner_log_warning() {
    runner_log ${runner_colors[yellow]}"${*}"${runner_colors[reset]}
}

runner_log_success() {
    runner_log ${runner_colors[green]}"${*}"${runner_colors[reset]}
}

## Returns unix time in nanoseconds
alias runner_time='date +%s%N'

## Returns a human readable duration in ms
runner_pretty_ms() {
    local -i ms=$((${1} / 1000000)) # nano to millis
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
    local -i parsed
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

declare -A runner_colors=(
    [black]=`echo -e '\e[30m'`
    [red]=`echo -e '\e[31m'`
    [green]=`echo -e '\e[32m'`
    [brown]=`echo -e '\e[33m'`
    [blue]=`echo -e '\e[34m'`
    [purple]=`echo -e '\e[35m'`
    [cyan]=`echo -e '\e[36m'`
    [light_gray]=`echo -e '\e[37m'`
    [gray]=`echo -e '\e[90m'`
    [light_red]=`echo -e '\e[91m'`
    [light_green]=`echo -e '\e[92m'`
    [yellow]=`echo -e '\e[93m'`
    [light_blue]=`echo -e '\e[94m'`
    [light_purple]=`echo -e '\e[95m'`
    [light_cyan]=`echo -e '\e[96m'`
    [white]=`echo -e '\e[97m'`
    [reset]=`echo -e '\e[0m'`
)

runner_colorize() {
    echo "${runner_colors[$2]}${1}${runner_colors[reset]}"
}

## List all defined functions beginning with `task_`
runner_get_defined_tasks() {
    local IFS=$'\n'
    for task in `typeset -F`; do
        [[ ${task} == 'declare -f task_'* ]] && echo ${task:16}
    done
}

## Fancy wrapper for `runner_get_defined_tasks`
runner_show_defined_tasks() {
    runner_log "Available tasks:"
    local tasks=`runner_get_defined_tasks`
    if [[ -z ${tasks} ]]; then
        runner_log "  ${runner_colors[light_gray]}<none>${runner_colors[reset]}"
        return
    fi
    for task in ${tasks}; do
        runner_log "  ${runner_colors[cyan]}${task}${runner_colors[reset]}"
    done
}

## Checks if program is accessible from current $PATH
runner_is_defined() {
    hash ${@} 2>/dev/null
}

runner_is_task_defined() {
    for task in ${@}; do
        runner_is_defined task_${task} || return
    done
}

runner_is_task_defined_verbose() {
    for task in ${@}; do
        if ! runner_is_defined task_${task}; then
            runner_log_error "Task '${task}' is not defined!"
            return 1
        fi
    done
}

runner_set_default_task() {
    runner_default_task=${1}
}

runner_run_task() {
    local task_color="${runner_colors[cyan]}${1}${runner_colors[reset]}"
    runner_log "Starting '${task_color}'..."
    local -i time_start=`runner_time`
    task_${1} ${runner_flags}
    local exit_code=${?}
    local -i time_end=`runner_time`
    local time_diff=`runner_pretty_ms $((time_end - time_start))`
    if [[ ${exit_code} -ne 0 ]]; then
        runner_log_error "Task '${1}'" \
            "failed after ${time_diff} (${exit_code})"
        return ${exit_code}
    fi
    runner_log "Finished '${task_color}" \
        "after ${runner_colors[purple]}${time_diff}${runner_colors[reset]}"
}

## Run tasks sequentially.
runner_sequence() {
    runner_is_task_defined_verbose ${@} || return
    for task in ${@}; do
        runner_run_task ${task} || return
    done
}

## Run tasks in parallel.
runner_parallel() {
    runner_is_task_defined_verbose ${@} || return 1
    local -a pid
    local -i exits=0
    for task in ${@}; do
        runner_run_task ${task} & pid+=(${!})
    done
    for pid in ${pid[@]}; do
        wait ${pid} || exits+=1
    done
    [[ ${exits} -eq 0 ]] && return 0
    [[ ${exits} -lt ${#} ]] && return 41 || return 42
}

## Starts the initial task.
runner_bootstrap() {
    ## Clear a trap we set up earlier
    trap - EXIT
    ## Run tasks
    if [[ -n ${runner_tasks} ]]; then
        runner_sequence ${runner_tasks} || exit
        return 0
    fi
    if runner_is_task_defined ${runner_default_task}; then
        runner_run_task ${runner_default_task} || exit
        return 0
    fi
    runner_log "Nothing to run."
    runner_show_defined_tasks
}
