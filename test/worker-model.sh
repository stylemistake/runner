#!/usr/bin/env bash
## worker-model.sh
## Basic test of the runner worker model.
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

cd "$(dirname "${0}")/.."
set -e

source lib/runner.sh


##  Tasks
## --------------------------------------------------------

task-default() {
  @depends -t group-{1,2}
}

## Common dependency required by groups
task-common-leaf() {
  echo "I have no dependencies!"
}

## Group 1
task-group-1() {
  @depends -t group-1-{foo,bar}
}

task-group-1-foo() {
  @depends -t common-leaf
  echo "group-1-foo: Sleeping for 1 second"
  sleep 1
}

task-group-1-bar() {
  @depends -t common-leaf
  echo "group-1-bar: Sleeping for 1 second"
  sleep 1
}

## Group 2
task-group-2() {
  @depends -t group-2-{foo,bar}
}

task-group-2-foo() {
  @depends -t common-leaf
  echo "group-2-foo: Sleeping for 2 seconds"
  sleep 2
}

task-group-2-bar() {
  @depends -t common-leaf
  echo "group-2-bar: Sleeping for 2 seconds"
  sleep 2
}


##  Bootstrap
## --------------------------------------------------------

runner_tasks=(default)
runner-master-init
