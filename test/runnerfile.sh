## Sample runnerfile

task_one() {
  runner_parallel end
}

task_two() {
  runner_parallel one end
}

task_three() {
  runner_parallel one two end
}

task_end() {
  # do nothing
  echo -n
}

task_default() {
  runner_parallel one two three end
}
