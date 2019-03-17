# runner.sh

## Resolve source directory
if [[ -z ${runner_src_dir} ]]; then
  runner_src_dir="$(dirname "${BASH_SOURCE[0]}")"
fi

## Include core dependencies
source "${runner_src_dir}/argparse.sh"
source "${runner_src_dir}/colorize.sh"
source "${runner_src_dir}/dir.sh"
source "${runner_src_dir}/list.sh"
source "${runner_src_dir}/logger.sh"
source "${runner_src_dir}/misc.sh"
source "${runner_src_dir}/time.sh"
source "${runner_src_dir}/runner-master.sh"
source "${runner_src_dir}/runner-slave.sh"

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

## Store completed tasks
runner_tasks_completed=()


##  Utility functions
## --------------------------------------------------------

runner-log() {
  logger-log "${@}"
}


##  Task runner functions
## --------------------------------------------------------

## Get a list of all tasks
## Usage: runner-get-tasks [--no-prefix]
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
  echo "Available tasks: $(runner-get-tasks)"
  local -a tasks
  ## Shellcheck pattern SC2207 to read an array
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
  if list-includes "${1}" -v --verbose; then
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
  ## Save bash option state
  ## See: https://superuser.com/a/946451/478493
  local bash_opt_state="$(set +o)"
  ## Run task in a controlled subshell
  set +e
  (
    set -e
    "${runner_task_prefix}${task}" "${task_args[@]}"
  )
  ## Save exit code
  local exit_code=${?}
  ## Restore bash option state
  eval "${bash_opt_state}"
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

# ## Runs multiple tasks
# ## Usage: runner-run-tasks [-p] [<task> ...]
# runner-run-tasks() {
#   if [[ ${1} == "-p" || ${1} == "--parallel" ]]; then
#     runner-run-tasks-parallel "${@:2}"
#     return ${?}
#   fi
#   if ! runner-is-task -v "${@}"; then
#     return 1
#   fi
#   for task in "${@}"; do
#     runner-run-task "${task}" || return ${?}
#   done
# }

# ## Run tasks in parallel.
# ## Usage: runner-run-tasks-parallel [<task> ...]
# runner-run-tasks-parallel() {
#   local -a pid
#   local -i exits=0
#   for task in "${@}"; do
#     runner-run-task "${task}" & pid+=(${!})
#   done
#   for pid in "${pid[@]}"; do
#     wait "${pid}" || exits+=1
#   done
#   [[ ${exits} -eq 0 ]] && return 0
#   [[ ${exits} -eq 1 ]] && return 1
#   [[ ${exits} -lt ${#} ]] && return 2
#   return 3
# }

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
