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
  test-list-index-of
  test-list-lookup
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
  local list_2=(A B C D E)
  local str
  str="$(list-join-by "," "${list[@]}")"
  [[ ${str} == "a,b,c,d,e" ]]
}

test-list-index-of() {
  local list=(a b c d e)
  local result
  result="$(list-index-of list a)"
  [[ ${result} == "0" ]]
  result="$(list-index-of list d)"
  [[ ${result} == "3" ]]
  result="$(list-index-of list f)"
  [[ -z ${result} ]]
}

test-list-lookup() {
  local list_keys=(a b c d e)
  local list_values=(A B C D E)
  local result
  result="$(list-lookup list_keys list_values a)"
  [[ ${result} == "A" ]]
  result="$(list-lookup list_keys list_values d)"
  [[ ${result} == "D" ]]
  result="$(list-lookup list_keys list_values f)"
  [[ -z ${result} ]]
}

for test in "${tests[@]}"; do
  logger-log -i "Running $(colorize -c cyan "'${test}'")"
  "${test}"
done
