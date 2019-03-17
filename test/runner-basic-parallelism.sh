#!/usr/bin/env bash
cd "$(dirname ${0})/.."
# set -e

source src/runner.sh

task-default() {
  runner-depends-on foo-1 foo-2
}

task-foo-1() {
  runner-depends-on foo-2
}

task-foo-2() {
  runner-depends-on foo-3
}

task-foo-3() {
  :
}

runner_tasks=(default)
runner-master-start
