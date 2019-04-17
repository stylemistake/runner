## runner.sh
## Main functions of the task runner.
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

## Resolve source directory
if [[ -z ${runner_lib_dir} ]]; then
  runner_lib_dir="$(dirname "${BASH_SOURCE[0]}")"
fi

## Include core dependencies
# shellcheck source=lib/annotation.sh
source "${runner_lib_dir}/annotation.sh"
# shellcheck source=lib/argparse.sh
source "${runner_lib_dir}/argparse.sh"
# shellcheck source=lib/colorize.sh
source "${runner_lib_dir}/colorize.sh"
# shellcheck source=lib/dir.sh
source "${runner_lib_dir}/dir.sh"
# shellcheck source=lib/list.sh
source "${runner_lib_dir}/list.sh"
# shellcheck source=lib/logger.sh
source "${runner_lib_dir}/logger.sh"
# shellcheck source=lib/misc.sh
source "${runner_lib_dir}/misc.sh"
# shellcheck source=lib/runner-master.sh
source "${runner_lib_dir}/runner-master.sh"
# shellcheck source=lib/runner-worker.sh
source "${runner_lib_dir}/runner-worker.sh"
# shellcheck source=lib/shell.sh
source "${runner_lib_dir}/shell.sh"
# shellcheck source=lib/time.sh
source "${runner_lib_dir}/time.sh"

## Default task
runner_default_task="default"

## Task prefix
runner_task_prefix="task-"

## Determine the initial passed arguments to the root script
runner_args=("${@}")

## Split arguments into tasks and flags.
## All flags are then passed on to tasks.
## E.g. --production
## NOTE: The actual splitting is done in runner-bootstrap.
runner_flags=()
runner_tasks=()


##  Utility functions
## --------------------------------------------------------

runner-log() {
  logger-log "${@}"
}


##  Task runner functions
## --------------------------------------------------------

## Get a list of all tasks
## Usage: runner-get-tasks [--with-prefix]
## TODO: --with-prefix is never used
# shellcheck disable=SC2120
runner-get-tasks() {
  local IFS=$'\n'
  local prefix_part="declare -f "
  local prefix_full="declare -f ${runner_task_prefix}"
  local tasks=()
  for task in $(typeset -F); do
    if [[ ${task} == "${prefix_full}"* ]]; then
      if [[ ${1} == '--with-prefix' ]]; then
        tasks+=("${task#$prefix_part}")
      else
        tasks+=("${task#$prefix_full}")
      fi
    fi
  done
  echo "${tasks[@]}"
}

## Get a human readable list of all tasks
## This one is meant to be used in CLI.
runner-show-tasks() {
  echo "Available tasks:"
  local -a tasks
  ## Shellcheck pattern SC2207 to read an array
  # shellcheck disable=SC2119
  IFS=" " read -r -a tasks <<< "$(runner-get-tasks)"
  if [[ ${#tasks[@]} -eq 0 ]]; then
    echo "  $(colorize -c light-grey \<none\>)"
    return
  fi
  for task in "${tasks[@]}"; do
    echo "  $(colorize -c cyan "${task}")"
  done
}

runner-is-task() {
  local task
  local verbose
  if list-in "${1}" -v --verbose; then
    verbose=1
    shift 1
  fi
  for task in "${@}"; do
    if ! hash "${runner_task_prefix}${task}" 2>/dev/null; then
      if [[ -n ${verbose} ]]; then
        runner-log -e "Task '${task}' is not defined!"
      fi
      return 1
    fi
  done
}

## Runs a single task
## Usage: runner-run-task <task> [<argument> ...]
runner-run-task() {
  local task="${1}"
  local task_args=("${@:2}")
  local task_str
  task_str="$(colorize -c cyan "'${task}'")"
  runner-log -a "Starting ${task_str}"
  ## Save time for calculating diff
  local -i time_start
  time_start="$(time-unix-ms)"
  ## Run task in controlled environment
  shell-opts-push
  set +o errexit
  (
    set -o errexit
    ## Suppress stdout
    @suppress-stdout() {
      exec >/dev/null
    }
    "${runner_task_prefix}${task}" "${task_args[@]}"
  )
  local exit_code="${?}"
  shell-opts-pop
  ## Calculate time diff
  local -i time_end
  time_end="$(time-unix-ms)"
  local time_diff
  time_diff="$(time-pretty-ms $((time_end - time_start)))"
  time_diff="$(colorize -c purple "${time_diff}")"
  ## Report error
  if [[ ${exit_code} -ne 0 ]]; then
    runner-log -e "Task ${task_str} failed after ${time_diff} (${exit_code})"
    return ${exit_code}
  fi
  ## Report success
  runner-log -a "Finished ${task_str} after ${time_diff}"
}

## Starts the initial task.
runner-bootstrap() {
  ## Parse arguments
  for arg in "${runner_args[@]}"; do
    if [[ ${arg} == -* ]]; then
      runner_flags+=("${arg}")
    else
      runner_tasks+=("${arg}")
    fi
  done
  ## Add default task if no tasks are provided
  if [[ ${#runner_tasks[@]} -eq 0 ]] \
      && runner-is-task "${runner_default_task}"; then
    runner_tasks+=("${runner_default_task}")
  fi
  ## Run tasks
  if [[ ${#runner_tasks[@]} -gt 0 ]]; then
    local task
    for task in "${runner_tasks[@]}"; do
      runner-run-task "${task}"
      local exit_code="${?}"
      if [[ ${exit_code} -ne 0 ]]; then
        return "${exit_code}"
      fi
    done
    return 0
  fi
  ## Nothing to run
  runner-show-tasks
}


##  Directory traversal functions
## --------------------------------------------------------

runner_dir_stack=()

runner-enter-dir() {
  local path="${1}"
  runner_dir_stack+=("${path}")
  runner-log "Entering '$(colorize light-grey "${path}")'"
  pushd "${path}" >/dev/null
}

runner-leave-dir() {
  local path="${runner_dir_stack[-1]}"
  unset 'runner_dir_stack[-1]'
  runner-log "Leaving '$(colorize light-grey "${path}")'"
  popd >/dev/null
}
