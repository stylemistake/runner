# runner-master.sh

runner_master_tasks=()
runner_master_tasks_pid=()
runner_master_deps=()
runner_master_deps_parent=()
runner_master_fifo=""
runner_master_fifo_dir="/tmp/runner-fifo.$$"

runner-master-init() {
  trap 'runner-master-exit ${?}' EXIT INT TERM KILL
  ## Publish master params
  runner_master_pid="${$}"
  ## Create fifo directory
  mkdir -p "${runner_master_fifo_dir}"
  ## Create master fifo
  runner_master_fifo="${runner_master_fifo_dir}/master.fifo"
  mkfifo "${runner_master_fifo}"
  ## Map fifo onto file descriptor
  exec 3<>"${runner_master_fifo}"
  ## Spawn workers
  local task
  for task in "${runner_tasks[@]}"; do
    runner-master-spawn-worker "${task}"
  done
  ## Read messages
  runner-master-log "Awaiting messages..."
  while true; do
    ## Break the loop when there are no more tasks to do
    if [[ ${#runner_master_tasks[@]} -eq 0 ]]; then
      break
    fi
    local msg
    runner-master-recv msg
    local msg_worker="${msg[0]}"
    local msg_command="${msg[1]}"
    local msg_args="${msg[@]:2}"
    ## Handle dependency
    if [[ ${msg_command} == 'dependency' ]]; then
      local task_dependency="${msg_args[0]}"
      ## Save dependency
      runner_master_deps+=("${task_dependency}")
      runner_master_deps_parent+=("${msg_worker}")
      ## Spawn a task
      if ! list-includes "${task_dependency}" "${runner_master_tasks[@]}"; then
        runner-master-spawn-worker "${task_dependency}"
      fi
    fi
    ## Handle finished task
    if [[ ${msg_command} == 'done' ]]; then
      ## Find and notify dependents
      local dep_i
      for dep_i in "${!runner_master_deps[@]}"; do
        local dep="${runner_master_deps[${dep_i}]}"
        local dep_parent="${runner_master_deps_parent[${dep_i}]}"
        if [[ ${msg_worker} == ${dep} ]]; then
          runner-master-send "${dep_parent}" resolve "${dep}"
        fi
      done
      ## Find and unset this task from currently running tasks
      list-unset-by runner_master_tasks "${msg_worker}"
    fi
  done
}

## Usage: ${0} <exit_code>
runner-master-exit() {
  trap - EXIT INT TERM KILL
  local exit_code="${1:-0}"
  runner-master-log "Exiting with ${exit_code}"
  ## Close pipes
  exec 3>&-
  ## Terminate own process tree
  kill 0
  ## Remove fifo directory
  rm -rf "${runner_master_fifo_dir}"
  ## Exit with provided exit code
  exit "${exit_code}"
}

runner-master-spawn-worker() {
  local task="${1}"
  local pid
  runner-master-log "Spawning '${task}'"
  runner-worker-init "${task}" & pid="${!}"
  runner_master_tasks+=("${task}")
  runner_master_tasks_pid+=("${pid}")
}

## Usage: ${0} <array_ref>
## Message structure: (<worker> <command> [<arg> ...])
runner-master-recv() {
  local __array_ref="${1}"
  local __array_ref_list="${1}[@]"
  read -ra "${__array_ref}" <&3
  runner-master-log "Recv: ${!__array_ref_list}"
}

## Usage: ${0} <worker> <command> [<arg> ...]
## Message structure: (<worker> <command> [<arg> ...])
runner-master-send() {
  local worker="${1}"
  shift 1
  local msg=("${worker}" "${@}")
  local worker_fifo="${runner_master_fifo_dir}/worker.${worker}.fifo"
  runner-master-log "Send: ${msg[@]}"
  echo "${msg[@]}" >"${worker_fifo}"
}

runner-master-log() {
  local signature
  signature="$(colorize -b -c red "master:")"
  runner-log -d "${signature} ${*}"
}
