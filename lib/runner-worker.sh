## runner-worker.sh
## Task worker
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

declare runner_task_prefix
declare runner_master_fifo
declare runner_master_fifo_dir

runner_worker_name=""
runner_worker_fifo=""
runner_worker_depends_tasks=()
runner_worker_depends_files=()
runner_worker_depends_dirs=()
runner_worker_provides_tasks=()
runner_worker_provides_files=()
runner_worker_provides_dirs=()

runner-worker-init() {
  set +e
  trap 'runner-worker-exit ${?}' EXIT INT TERM
  local task="${1}"
  runner_worker_name="${task}"
  runner_worker_fifo="${runner_master_fifo_dir}/worker.${task}.fifo"
  ## Create worker fifo
  mkfifo "${runner_worker_fifo}"
  ## Map fifos onto file descriptors
  exec 3<>"${runner_worker_fifo}"
  exec 4<>"${runner_master_fifo}"
  ## Run task
  runner-worker-log "Ready"
  ## Parse annotations
  annotation-declare @depends
  annotation-declare @provides
  annotation-parse \
    "${runner_task_prefix}${runner_worker_name}" \
    runner-worker-annotation-handler
  ## Wait for dependencies
  runner-worker-wait-for-dependencies
  ## Check if needs rebuild
  if runner-worker-needs-rebuild; then
    ## Run task
    runner-run-task "${runner_worker_name}"
    local exit_code="${?}"
  else
    runner-log -i "Skipping $(colorize -c cyan "'${runner_worker_name}'")"
    local exit_code="0"
  fi
  if [[ ${exit_code} -gt 0 ]]; then
    runner-worker-send "error" "${exit_code}"
    return 0
  fi
  runner-worker-send "done"
}

## Usage: ${0} <exit_code>
runner-worker-exit() {
  trap - EXIT INT TERM
  local exit_code="${1:-0}"
  runner-worker-log "Exiting with ${exit_code}"
  if [[ ${exit_code} -ne 0 ]]; then
    runner-log -e "Task '${runner_worker_name}' failed (${exit_code})"
  fi
  ## Close pipes
  exec 3>&-
  exec 4>&-
  ## Terminate own process tree
  ## Use SIGPIPE because it doesn't produce "Terminated" messages
  ## See: https://stackoverflow.com/a/5722874/2245739
  # kill -s PIPE 0
  ## Exit with provided exit code
  exit "${exit_code}"
}

runner-worker-annotation-handler() {
  if [[ ${1} == '@depends' ]]; then
    eval "runner-worker-depends ${*:2}"
  elif [[ ${1} == '@provides' ]]; then
    eval "runner-worker-provides ${*:2}"
  fi
}

runner-worker-depends() {
  local obj
  local obj_type
  ## Sort dependencies into separate piles
  while [[ ${#} -ne 0 ]]; do
    if [[ ${1} == -* ]]; then
      local obj_type="${1}"
      shift 1
      continue
    fi
    local obj="${1}"
    shift 1
    if [[ ${obj_type} == "-t" ]]; then
      runner_worker_depends_tasks+=("${obj}")
      continue
    fi
    if [[ ${obj_type} == "-f" ]]; then
      runner_worker_depends_files+=("${obj}")
      continue
    fi
    if [[ ${obj_type} == "-d" ]]; then
      runner_worker_depends_dirs+=("${obj}")
      continue
    fi
    logger-log -e "Unrecognized @depends flag: '${obj_type}'"
    exit 1
  done
}

runner-worker-provides() {
  local obj
  local obj_type
  ## Sort dependencies into separate piles
  while [[ ${#} -ne 0 ]]; do
    if [[ ${1} == -* ]]; then
      local obj_type="${1}"
      shift 1
      continue
    fi
    local obj="${1}"
    shift 1
    if [[ ${obj_type} == "-t" ]]; then
      runner_worker_provides_tasks+=("${obj}")
      continue
    fi
    if [[ ${obj_type} == "-f" ]]; then
      runner_worker_provides_files+=("${obj}")
      continue
    fi
    if [[ ${obj_type} == "-d" ]]; then
      runner_worker_provides_dirs+=("${obj}")
      continue
    fi
    logger-log -e "Unrecognized @provides flag: '${obj_type}'"
    exit 1
  done
}

runner-worker-wait-for-dependencies() {
  local dep
  ## Send dependencies to master process
  for dep in "${runner_worker_depends_tasks[@]}"; do
    runner-worker-send "dependency" "${dep}"
  done
  ## Start blocking
  while true; do
    ## Stop blocking when there are no more depencies
    if [[ ${#runner_worker_depends_tasks[@]} -eq 0 ]]; then
      break
    fi
    ## Receive message
    local msg
    runner-worker-recv msg
    local msg_command="${msg[1]}"
    local msg_args=("${msg[@]:2}")
    ## Handle resolved dependency
    if [[ ${msg_command} == "resolve" ]]; then
      ## Unset matching dependency (no longer blocking)
      list-unset-by runner_worker_depends_tasks "${msg_args[0]}"
    fi
  done
}

runner-worker-needs-rebuild() {
  file-compare \
    -i -f "${runner_worker_depends_files[@]}" \
    -i -d "${runner_worker_depends_dirs[@]}" \
    -o -f "${runner_worker_provides_files[@]}" \
    -o -d "${runner_worker_provides_dirs[@]}"
}

## Usage: ${0} <array_ref>
## Message structure: (<worker> <command> [<arg> ...])
runner-worker-recv() {
  local __array_ref="${1}"
  local __array_ref_list="${1}[@]"
  # shellcheck disable=SC2229
  read -ra "${__array_ref}" <&3
  runner-worker-log "Recv: ${!__array_ref_list}"
}

## Usage: ${0} <command> [<arg> ...]
## Message structure: (<worker> <command> [<arg> ...])
runner-worker-send() {
  local worker="${runner_worker_name}"
  local msg=("${worker}" "${@}")
  runner-worker-log "Send: ${msg[*]}"
  echo "${msg[@]}" >&4
}

runner-worker-log() {
  local signature
  signature="$(colorize -b -c cyan "${runner_worker_name}:")"
  runner-log -d "${signature} ${*}"
}
