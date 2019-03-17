# list.sh
## Functions for working with lists

## Usage: ${0} <predicate> [<value_1> <value_2> ...]
list-includes() {
  for arg in "${@:2}"; do
    if [[ ${1} == ${arg} ]]; then
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
## Usage: ${0} <list_ref> <predicate>
## Example: ${0} cities "New York"
list-index-of() {
  local _list_ref="${1}[@]"
  local predicate="${2}"
  local item
  local -i index=0
  for item in "${!_list_ref}"; do
    if [[ ${item} == ${predicate} ]]; then
      echo "${index}"
      return
    fi
    let index+=1
  done
}

## Lookup value in second array by the value in first array.
## This is similar to lookup in dictionaries or hashmaps.
## Usage: ${0} <list_ref_keys> <list_ref_values> <predicate>
## Example: ${0} cities cities_state "New York"
list-lookup() {
  local _list_ref="${1}[@]"
  local predicate="${3}"
  local value_ref
  local item
  local -i index=0
  for item in "${!_list_ref}"; do
    if [[ ${item} == ${predicate} ]]; then
      value_ref="${2}[${index}]"
      echo "${!value_ref}"
      return
    fi
    let index+=1
  done
}
