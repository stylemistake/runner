#!/usr/bin/env bash

## Default task
declare runner_default_task="task-default"

## Task prefix
declare runner_task_prefix="task-"

## Trap EXIT signal to bootstrap the runner.
## Works like a charm - your script ends, tasks start to run.
## Trap resets after bootstrapping.
trap '[[ ${?} -eq 0 ]] && runner-bootstrap' EXIT

## Expand aliases
shopt -s expand_aliases

## Determine the initial passed arguments to the root script
declare -a runner_args=("${@}")

## Split arguments into tasks and flags.
## All flags are then passed on to tasks.
## E.g. --production
## NOTE: The actual splitting is done in runner-bootstrap.
declare -a runner_flags
declare -a runner_tasks


##  Shorthand aliases
## --------------------------------------------------------

alias @bootstrap="runner-bootstrap"
alias @colorize="runner-colorize"
alias @get-tasks="runner-get-tasks"
alias @is-command="runner-is-command"
alias @is-task="runner-is-task"
alias @log-error="runner-log-error"
alias @log-notice="runner-log-notice"
alias @log-success="runner-log-success"
alias @log-warning="runner-log-warning"
alias @log="runner-log"
alias @run-command="runner-run-command"
alias @run-tasks="runner-run-tasks"
alias @enter-dir="runner-enter-dir"
alias @leave-dir="runner-leave-dir"


##  Logging functions
## --------------------------------------------------------

## Logs a message with a timestamp
runner-log() {
  local timestamp="$(runner-date +%T.%3N)"
  echo "[$(runner-colorize grey "${timestamp}")] ${*}"
}

## Variations of log with colors
runner-log-error() {
  runner-log "$(runner-colorize red "${@}")"
}

runner-log-warning() {
  runner-log "$(runner-colorize light-yellow "${@}")"
}

runner-log-success() {
  runner-log "$(runner-colorize green "${@}")"
}

runner-log-notice() {
  runner-log "$(runner-colorize grey "${@}")"
}


##  Utility functions
## --------------------------------------------------------

## Checks if program is accessible from current $PATH
runner-is-command() {
  hash "${@}" 2>/dev/null
}

## Checks if word is in the list.
## Usage: runner-contains <predicate> [<word> ...]
runner-contains() {
  local item
  local predicate="${1}"
  shift
  for item; do
    [[ "${item}" == "${predicate}" ]] && return 0
  done
  return 1
}

## Alias for coreutils date
alias runner-date="date"

## Returns unix time in ms
alias runner-time="runner-date +%s%3N"

## Returns a human readable duration in ms
runner-pretty-ms() {
  local -i ms="${1}"
  local result
  ## If zero or nothing
  if [[ -z ${ms} || ${ms} -lt 1 ]]; then
    echo "0 ms"
    return
  ## Only ms
  elif [[ ${ms} -lt 1000 ]]; then
    echo "${ms} ms"
    return
  ## Only seconds with trimmed ms point
  elif [[ ${ms} -lt 60000 ]]; then
    result=$((ms / 1000 % 60)).$((ms % 1000))
    echo "${result:0:4} s"
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
  echo "${result}"
}

## Color definitions and colorize function
## NOTE: Associative arrays only work on Bash 4
if ((BASH_VERSINFO[0] >= 4)); then
  declare -A runner_colors=(
    [black]="$(echo -e '\e[30m')"
    [red]="$(echo -e '\e[31m')"
    [green]="$(echo -e '\e[32m')"
    [yellow]="$(echo -e '\e[33m')"
    [blue]="$(echo -e '\e[34m')"
    [purple]="$(echo -e '\e[35m')"
    [cyan]="$(echo -e '\e[36m')"
    [light-grey]="$(echo -e '\e[37m')"
    [grey]="$(echo -e '\e[90m')"
    [light-red]="$(echo -e '\e[91m')"
    [light-green]="$(echo -e '\e[92m')"
    [light-yellow]="$(echo -e '\e[93m')"
    [light-blue]="$(echo -e '\e[94m')"
    [light-purple]="$(echo -e '\e[95m')"
    [light-cyan]="$(echo -e '\e[96m')"
    [white]="$(echo -e '\e[97m')"
    [reset]="$(echo -e '\e[0m')"
  )

  runner-colorize() {
    echo "${runner_colors[$1]}${*:2}${runner_colors[reset]}"
  }
else
  runner-colorize() {
    echo "${*:2}"
  }
fi


##  Task runner functions
## --------------------------------------------------------

## Get a list of all tasks
## Usage: runner-get-tasks [--no-prefix]
runner-get-tasks() {
  local IFS=$'\n'
  local prefix_part="declare -f "
  local prefix_full="declare -f ${runner_task_prefix}"
  for task in $(typeset -F); do
    if [[ ${task} == "${prefix_full}"* ]]; then
      if [[ ${1} == '--no-prefix' ]]; then
        echo "${task#$prefix_full}"
      else
        echo "${task#$prefix_part}"
      fi
    fi
  done
}

## Get a human readable list of all tasks
## This one is meant to be used in CLI.
runner-show-tasks() {
  runner-log "Available tasks:"
  local -a tasks
  ## Shellcheck pattern SC2207 to read an array
  IFS=" " read -r -a tasks <<< "$(runner-get-tasks --no-prefix)"
  if [[ ${#tasks[@]} -eq 0 ]]; then
    runner-log "  $(runner-colorize light-grey \<none\>)"
    return
  fi
  for task in "${tasks[@]}"; do
    runner-log "  $(runner-colorize cyan "${task#$runner_task_prefix}")"
  done
}

runner-is-task() {
  for task in "${@}"; do
    if ! runner-is-command "${task}"; then
      return 1
    fi
    if [[ ${task} != "${runner_task_prefix}"* ]]; then
      return 1
    fi
  done
}

runner-is-task-verbose() {
  for task in "${@}"; do
    if ! runner-is-command "${task}"; then
      runner-log-error "Task '${task}' is not defined!"
      return 1
    fi
  done
}

## Runs a single task
## Usage: runner-run-task <task> [<argument> ...]
runner-run-task() {
  local task_name="${1#$runner_task_prefix}"
  if runner-is-task "${1}"; then
    local task_color="$(runner-colorize cyan "${task_name}")"
  else
    local task_color="$(runner-colorize yellow "${task_name}")"
  fi
  runner-log "Starting '${task_color}'..."
  local -i time_start="$(runner-time)"
  "${1}" "${@:2}" "${runner_flags[@]}"
  local exit_code=${?}
  local -i time_end="$(runner-time)"
  local time_diff="$(runner-pretty-ms $((time_end - time_start)))"
  if [[ ${exit_code} -ne 0 ]]; then
    runner-log-error "Task '${task_name}'" \
      "failed after ${time_diff} (${exit_code})"
    return ${exit_code}
  fi
  runner-log "Finished '${task_color}'" \
    "after $(runner-colorize purple "${time_diff}")"
}

## Runs tasks.
## Usage: runner-run-tasks [-p] [<task> ...]
runner-run-tasks() {
  if [[ ${1} == "-p" || ${1} == "--parallel" ]]; then
    runner-run-tasks-parallel "${@:2}"
    return ${?}
  fi
  runner-is-task-verbose "${@}" || return 1
  for task in "${@}"; do
    runner-run-task "${task}" || return ${?}
  done
}

## Run tasks in parallel.
## Usage: runner-run-tasks-parallel [<task> ...]
runner-run-tasks-parallel() {
  runner-is-task-verbose "${@}" || return 1
  local -a pid
  local -i exits=0
  for task in "${@}"; do
    runner-run-task "${task}" & pid+=(${!})
  done
  for pid in "${pid[@]}"; do
    wait "${pid}" || exits+=1
  done
  [[ ${exits} -eq 0 ]] && return 0
  [[ ${exits} -eq 1 ]] && return 1
  [[ ${exits} -lt ${#} ]] && return 2
  return 3
}

## Outputs command before execution
## Usage: runner-run-command <command> [<argument> ...]
runner-run-command() {
  runner-log-notice "${@}"
  "${@}"
}

## Starts the initial task.
runner-bootstrap() {
  ## Clear a trap we set up earlier
  trap - EXIT
  ## Parse arguments
  for arg in "${runner_args[@]}"; do
    if [[ ${arg} == -* ]]; then
      runner_flags+=("${arg}")
    else
      runner_tasks+=("${arg}")
    fi
  done
  ## Run tasks
  if [[ ${#runner_tasks[@]} -gt 0 ]]; then
    runner-run-tasks "${runner_tasks[@]}" || exit ${?}
    return 0
  fi
  if runner-is-task "${runner_default_task}"; then
    runner-run-task "${runner_default_task}" || exit ${?}
    return 0
  fi
  ## Nothing to run
  runner-show-tasks
}

## Fallbacks for GNU date
## Detecting GNU coreutils http://stackoverflow.com/a/8748344/319952
if ! date --version >/dev/null 2>&1; then
  if hash gdate 2>/dev/null; then
    alias runner-date="gdate"
  else
    ## Don't use nanoseconds feature of GNU date
    alias runner-time="runner-date +%s000"
    ## Don't print milliseconds in log messages
    runner-log() {
      local timestamp="$(runner-date +%T)"
      echo "[$(runner-colorize grey "${timestamp}")] ${*}"
    }
  fi
fi


##  Directory traversal functions
## --------------------------------------------------------

runner_dir_stack=()

runner-enter-dir() {
  local path="${1}"
  runner_dir_stack+=("${path}")
  runner-log "Entering '$(runner-colorize light-grey "${path}")'"
  pushd "${path}" >/dev/null
}

runner-leave-dir() {
  local path="${runner_dir_stack[-1]}"
  unset 'runner_dir_stack[-1]'
  runner-log "Leaving '$(runner-colorize light-grey "${path}")'"
  popd >/dev/null
}



##  Compatibility with runner v0.x.x
## --------------------------------------------------------

# declare -a runner_deprecations_shown=()

# runner-deprecation-warning() {
#   runner-log-error ""
#   "${@}"
# }

alias runner_bootstrap="runner-bootstrap"
alias runner_colorize="runner-colorize"
alias runner_get_defined_tasks="runner-get-tasks"
alias runner_is_defined="runner-is-command"

runner_is_task_defined() {
  runner-is-task "${runner_task_prefix}${1}"
}

runner_is_task_defined_verbose() {
  runner-is-task-verbose "${runner_task_prefix}${1}"
}

alias runner_log="runner-log"
alias runner_log_error="runner-log-error"
alias runner_log_notice="runner-log-notice"
alias runner_log_success="runner-log-success"
alias runner_log_warning="runner-log-warning"
alias runner_parallel="runner-run-tasks-parallel"
alias runner_pretty_ms="runner-pretty-ms"
alias runner_run="runner-run-command"
alias runner_run_task="runner-run-task"
alias runner_sequence="runner-run-tasks"
alias runner_show_defined_tasks="runner-show-tasks"
