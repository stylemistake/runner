# runner-master.sh

runner_master_tasks=()
runner_master_tasks_pid=()
runner_master_deps=()
runner_master_deps_origin=()

runner-master-start() {
  ## Publish master params
  runner_master_fifo="storage/master.fifo"
  runner_master_pid="${$}"
  ## Create master fifo
  rm -rf storage
  mkdir -p storage
  mkfifo "${runner_master_fifo}"
  ## Spawn initial tasks
  local task
  for task in "${runner_tasks[@]}"; do
    runner-master-spawn-task "${task}"
  done
  ## Read messages from tasks
  runner-master-log "Awaiting messages..."
  while true; do
    local msg
    IFS=":" read -ra msg < "${runner_master_fifo}"
    runner-master-log "Received message: ${msg[@]}"
    ## Handle dependency
    if [[ ${msg[0]} == 'dependency' ]]; then
      local task="${msg[1]}"
      local task_dependency="${msg[2]}"
      ## Save dependency
      runner_master_deps+=("${task_dependency}")
      runner_master_deps_origin+=("${task}")
      ## Spawn a task
      if ! list-includes "${task_dependency}" "${runner_master_tasks[@]}"; then
        runner-master-spawn-task "${task_dependency}"
      fi
    fi
    ## Handle finished task
    if [[ ${msg[0]} == 'finished' ]]; then
      local task="${msg[1]}"
      local origin
      origin="$(list-lookup runner_master_deps{,_origin} "${task}")"
      ## Signal dependency origin to resume
      if [[ -n ${origin} ]]; then
        runner-master-log "Send msg: resume (${origin})"
        echo "resume" > "storage/${origin}.fifo"
      fi
    fi
  done
  echo "$$: Waiting"
  wait
}

runner-master-spawn-task() {
  local task="${1}"
  runner_master_tasks+=("${task}")
  runner-master-log "Spawning '${task}'"
  runner-slave-init "${task}" \
    & runner_master_tasks_pid+=("${!}")
}

runner-master-log() {
  local signature
  signature="$(colorize -b -c cyan "master(${runner_master_pid}):")"
  runner-log -d "${signature} ${*}"
}
