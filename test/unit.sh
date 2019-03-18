#!/usr/bin/env bash
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
