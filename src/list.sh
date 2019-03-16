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
