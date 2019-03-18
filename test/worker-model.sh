#!/usr/bin/env bash
cd "$(dirname "${0}")/.."
# set -e

source src/runner.sh

@depends() {
  runner-worker-depends "${@}"
}


##  Tasks
## --------------------------------------------------------

task-default() {
  @depends group-{1,2}
}

## Common dependency required by groups
task-common-leaf() {
  echo "I have no dependencies!"
}

## Group 1
task-group-1() {
  @depends group-1-{foo,bar}
}

task-group-1-foo() {
  @depends common-leaf
  echo "group-1-foo: Sleeping for 1 second"
  sleep 1
}

task-group-1-bar() {
  @depends common-leaf
  echo "group-1-bar: Sleeping for 1 second"
  sleep 1
}

## Group 2
task-group-2() {
  @depends group-2-{foo,bar}
}

task-group-2-foo() {
  @depends common-leaf
  echo "group-2-foo: Sleeping for 2 seconds"
  sleep 2
}

task-group-2-bar() {
  @depends common-leaf
  echo "group-2-bar: Sleeping for 2 seconds"
  sleep 2
}


##  Bootstrap
## --------------------------------------------------------

runner_tasks=(default)
runner-master-init
