#!/bin/bash

## NOTE: This script depends on runner.sh to be loaded first.

## Runnerfile names that CLI will be looking for in current directory.
declare -ga runner_file_default_names=(
    'runnerfile.sh'
    'Runnerfile.sh'
    'runnerfile'
    'Runnerfile'
)

## Global variables that hold CLI settings
declare -g runner_file
declare -g runner_directory
declare -g runner_list_tasks

## Outputs an error message and exits the script
runner_cli_error() {
    trap - EXIT
    runner_log_error "${@}"
    exit 2
}

## Outputs a nice help message
runner_cli_help() {
    trap - EXIT
    echo "Usage: ${0} [options] [task] [task_options] ..."
    echo "Options:"
    echo "  -C <dir>, --directory=<dir>  Change to <dir> before doing anything."
    echo "  -f <file>, --file=<file>     Use <file> as a runnerfile."
    echo "  -l, --list-tasks             List available tasks."
    echo "  -h, --help                   Print this message and exit."
    exit 0
}

## Outputs a list of tasks
runner_cli_list_tasks() {
    trap - EXIT
    runner_get_defined_tasks
    exit 0
}

## Parses CLI-specific flags.
## Must take "${runner_args[@]}" as the argument.
runner_cli_parse_args() {
    ## Clean up currently defined arguments
    runner_args=()
    ## Iterate over the provided arguments
    while [[ ${#} -gt 0 ]]; do
        ## Stop parsing after the first non-flag argument
        if [[ ${1} != -* ]]; then
            break
        fi
        ## Help message
        if [[ ${1} == '-h' || ${1} == '--help' ]]; then
            runner_cli_help
        fi
        ## List tasks
        if [[ ${1} == '-l' || ${1} == '--list-tasks' ]]; then
            runner_list_tasks=true
        fi
        ## Runnerfile override
        if [[ ${1} == '-f' ]]; then
            [[ -z ${2} ]] && runner_cli_error "Missing an argument after ${1}"
            runner_file="${2}"
            shift 2
            continue
        fi
        if [[ ${1} == '--file='* ]]; then
            runner_file="${1#*=}"
            shift 1
            continue
        fi
        ## Current directory override
        if [[ ${1} == '-C' ]]; then
            [[ -z ${2} ]] && runner_cli_error "Missing an argument after ${1}"
            runner_directory="${2}"
            shift 2
            continue
        fi
        if [[ ${1} == '--directory='* ]]; then
            runner_directory="${1#*=}"
            shift 1
            continue
        fi
        ## Append unclassified flags back to runner_args
        runner_args+=("${1}")
        shift 1
    done
    ## Append remaining arguments that will be passed to the
    ## bootstrap function
    runner_args+=("${@}")
}

## Parse the actual arguments
runner_cli_parse_args "${runner_args[@]}"

## Try to change the current directory
if [[ -n ${runner_directory} ]]; then
    if [[ ! -d ${runner_directory} ]]; then
        runner_cli_error "'${runner_directory}' is not a directory!"
    fi
    cd "${runner_directory}" || runner_cli_error "Could not change directory!"
fi

## Try to find a runnerfile
if [[ -n ${runner_file} ]]; then
    if [[ ! -f ${runner_file} ]]; then
        runner_cli_error "'${runner_file}' is not a file!"
    fi
else
    for file in "${runner_file_default_names[@]}"; do
        if [[ -f ${file} ]]; then
            runner_file="${file}"
            break
        fi
    done
fi

## Runnerfile not found
if [[ -z ${runner_file} ]]; then
    runner_cli_error 'No runnerfile found.'
fi

## Source the runnerfile
# shellcheck source=/dev/null
source "${runner_file}"

if [ -n "${runner_list_tasks}" ]; then
    runner_cli_list_tasks
fi
