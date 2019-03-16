#!/usr/bin/env bash
cd "$(dirname ${0})/.."
set -e

source src/argparse.sh
source src/list.sh
source src/logger.sh
source src/colorize.sh

tests=(
  test-argparse
  test-list-includes
  test-list-join-by
)

test-argparse() {
  argparse-parse -Stc --long 123
  argparse-has-args -S -t -c
  argparse-has-args --long
  local param
  param="$(argparse-get-arg-param --long)"
  [[ ${param} == "123" ]]
}

test-list-includes() {
  local list=(a b c d e)
  list-includes a "${list[@]}"
}

test-list-join-by() {
  local list=(a b c d e)
  local str
  str="$(list-join-by "," "${list[@]}")"
  [[ ${str} == "a,b,c,d,e" ]]
}

for test in "${tests[@]}"; do
  logger-log -i "Running $(colorize -c cyan "'${test}'")"
  "${test}"
done
