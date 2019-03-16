#!/usr/bin/env bash
cd "$(dirname ${0})/.."
set -e

source src/runner.sh

task-default() {
  runner-depends-on foo1 foo2
}

task-foo1() {
  runner-depends-on foo2
}

task-foo2() {
  runner-depends-on foo3
}

task-foo3() {
  :
}

runner-bootstrap
