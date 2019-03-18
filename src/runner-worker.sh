## runner-worker.sh
## Task worker

declare runner_master_fifo
declare runner_master_fifo_dir

runner_worker_name=""
runner_worker_fifo=""

runner-worker-init() {
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
  runner-run-task "${runner_worker_name}"
  runner-worker-send "done"
}

## Usage: ${0} <exit_code>
runner-worker-exit() {
  trap - EXIT INT TERM
  local exit_code="${1:-0}"
  runner-worker-log "Exiting with ${exit_code}"
  ## Close pipes
  exec 3>&-
  exec 4>&-
  ## Terminate own process tree
  kill 0
  ## Exit with provided exit code
  exit "${exit_code}"
}

runner-worker-depends() {
  local deps=("${@}")
  local dep
  for dep in "${deps[@]}"; do
    runner-worker-send "dependency" "${dep}"
  done
  ## Start blocking
  while true; do
    ## Stop blocking when there are no more depencies
    if [[ ${#deps[@]} -eq 0 ]]; then
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
      list-unset-by deps "${msg_args[0]}"
    fi
  done
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
