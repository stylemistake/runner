#!/usr/bin/env bash
## unit.sh
## Script for running unit tests.
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

cd "$(dirname "${0}")/.."
set -e

source src/runner.sh

## Import tests
tests=()
source test/unit/argparse.sh
source test/unit/list.sh

## Run tests
for test in "${tests[@]}"; do
  logger-log -i "Running test $(colorize -c cyan "'${test}'")"
  "${test}"
done
