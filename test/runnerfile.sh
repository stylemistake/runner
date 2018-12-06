## Sample runnerfile

task-default() {
  @run-tasks -p task-one task-two task-three task-end
}

task-one() {
  @run-tasks -p task-end
}

task-two() {
  @run-tasks -p task-one task-end
}

task-three() {
  @run-tasks -p task-one task-two task-end
}

task-end() {
  # do nothing
  echo -n
}
