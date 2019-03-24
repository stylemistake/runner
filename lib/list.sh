## list.sh
## Functions for working with lists
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

## Usage: ${0} <predicate> [<value_1> <value_2> ...]
list-in() {
  for arg in "${@:2}"; do
    if [[ ${1} == "${arg}" ]]; then
      return 0
    fi
  done
  return 1
}

## Usage: ${0} <array_ref> <predicate>
list-includes() {
  local __array_ref_list="${1}[@]"
  local predicate="${2}"
  for arg in "${!__array_ref_list}"; do
    if [[ ${arg} == "${predicate}" ]]; then
      return 0
    fi
  done
  return 1
}

## Usage: ${0} <separator> [<value> ...]
list-join-by() {
  local IFS="${1}"
  shift
  echo "${*}"
}

## Returns an index of a given value inside the list.
## Usage: ${0} <array_ref> <predicate>
## Example: ${0} cities "New York"
list-index-of() {
  local __array_ref_list="${1}[@]"
  local predicate="${2}"
  local item
  local -i index=0
  for item in "${!__array_ref_list}"; do
    if [[ ${item} == "${predicate}" ]]; then
      echo "${index}"
      return
    fi
    (( index+=1 ))
  done
}

## Lookup value in second array by the value in first array.
## This is similar to lookup in dictionaries or hashmaps.
## Usage: ${0} <array_ref_keys> <array_ref_values> <predicate>
## Example: ${0} cities cities_state "New York"
list-lookup() {
  local __array_ref_keys_list="${1}[@]"
  local __array_ref_values="${2}"
  local predicate="${3}"
  local item
  local -i index=0
  for item in "${!__array_ref_keys_list}"; do
    if [[ ${item} == "${predicate}" ]]; then
      local __value_ref="${__array_ref_values}[${index}]"
      echo "${!__value_ref}"
      return
    fi
    (( index+=1 ))
  done
}

## Usage: ${0} <array_ref> <predicate>
list-unset-by() {
  local __array_ref="${1}"
  local indexes=()
  eval 'indexes=("${!'"${__array_ref}"'[@]}")'
  local predicate="${2}"
  local index
  for index in "${indexes[@]}"; do
    local __item_ref="${__array_ref}[${index}]"
    local item="${!__item_ref}"
    if [[ ${item} == "${predicate}" ]]; then
      unset "${__array_ref}[${index}]"
    fi
  done
}
