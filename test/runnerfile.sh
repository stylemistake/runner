## Sample runnerfile

task_p1() {
  runner_parallel end
}

task_p2() {
  runner_parallel p1 end
}

task_p3() {
  runner_parallel p1 p2 end
}

task_fail() {
  return 1
}

task_end() {
  # do nothing
  echo -n
}

task_test_parallel() {
  runner_parallel p1 p2 p3 end
}

task_test_correct_exit_code_in_sequence() {
  if runner_sequence fail; then
    return 1
  else
    return 0
  fi
}

task_default() {
  runner_sequence \
    test_parallel \
    test_correct_exit_code_in_sequence
}
