# runner-slave.sh

runner_slave_task=""
runner_slave_pid=""
runner_slave_fifo=""

runner-depends-on() {
  runner-slave-depends-on "${@}"
}

runner-slave-init() {
  local task="${1}"
  runner_slave_task="${task}"
  runner_slave_pid="${BASHPID}"
  runner_slave_fifo="storage/${task}.fifo"
  mkfifo "${runner_slave_fifo}"
  runner-run-task "${task}"
  echo "finished:${runner_slave_task}" > "${runner_master_fifo}"
}

runner-slave-depends-on() {
  local task
  for task in "${@}"; do
    runner-slave-log "Depending on '${task}'"
    echo "dependency:${runner_slave_task}:${task}" > "${runner_master_fifo}"
  done
  runner-slave-wait-for-signal USR1
}

runner-slave-log() {
  local signature
  signature="$(colorize -b -c cyan "${runner_slave_task}(${runner_slave_pid}):")"
  runner-log -d "${signature} ${*}"
}

runner-slave-wait-for-signal() {
  local signal="${1}"
  local signal_received=""
  trap "runner-slave-log exiting; exit 1" INT KILL TERM EXIT
  local msg
  IFS=":" read -ra msg < "${runner_slave_fifo}"
  runner-slave-log "Received message: ${msg[@]}"
  trap - INT KILL TERM EXIT
}
