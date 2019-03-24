## list.sh
## Unit tests for list.sh
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

# shellcheck disable=SC2034
# shellcheck disable=SC2154

tests+=(
  test-list-in
  test-list-includes
  test-list-join-by
  test-list-index-of
  test-list-lookup
  test-list-unset-by
)

test-list-in() {
  local list=(a b c d e)
  list-in a "${list[@]}"
  ! list-in x "${list[@]}"
}

test-list-includes() {
  local list=(a b c d e)
  list-includes list a
  ! list-includes list x
}

test-list-join-by() {
  local list=(a b c d e)
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

test-list-unset-by() {
  local list=(a b c d e)
  [[ ${#list[@]} -eq 5 ]]
  list-unset-by list d
  [[ ${#list[@]} -eq 4 ]]
  list-unset-by list b
  [[ ${#list[@]} -eq 3 ]]
  [[ ${list[0]} == 'a' ]]
  [[ -z ${list[1]} ]]
  [[ ${list[2]} == 'c' ]]
  [[ -z ${list[3]} ]]
  [[ ${list[4]} == 'e' ]]
  list-unset-by list b
  [[ ${#list[@]} -eq 3 ]]
  ## Verify that we don't leak local variables
  [[ -z ${indexes} ]]
}
