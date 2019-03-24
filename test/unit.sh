#!/usr/bin/env bash
## unit.sh
## Script for running unit tests.
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

# shellcheck disable=SC2154
# shellcheck disable=SC1090

cd "$(dirname "${0}")/.."
set -e

source lib/runner.sh

## Import tests
tests=()
for unit in test/unit/*.sh; do
  source "${unit}"
done

## Run tests
for test in "${tests[@]}"; do
  logger-log -i "Running test $(colorize -c cyan "'${test}'")"
  "${test}"
done
