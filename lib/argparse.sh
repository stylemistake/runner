## argparse.sh
## Argument parsing facility
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

## A copy of arguments
declare -a argparse_args=()

## Initialize
## Usage: ${0} [<args> ...]
argparse-parse() {
  ## Parse arguments
  for arg in "${@}"; do
    ## Long flag
    if [[ ${arg} == --* ]]; then
      argparse_args+=("${arg}")
    ## Short flag
    elif [[ ${arg} == -* ]]; then
      ## Iterate over all short flags
      for (( i = 1; i < ${#arg}; i++ )); do
        argparse_args+=("-${arg:$i:1}")
      done
    ## Rest
    else
      argparse_args+=("${arg}")
    fi
  done
}

## Check if argument was passed to this program
## Usage: ${0} [<args> ...]
argparse-has-args() {
  for arg in "${argparse_args[@]}"; do
    if list-in "${arg}" "${@}"; then
      return 0
    fi
  done
  return 1
}

## Get a parameter right next to the flag, e.g. --flag <param>
## Usage: ${0} [<flag> ...]
argparse-get-arg-param() {
  local return_next=
  for arg in "${argparse_args[@]}"; do
    if [[ -n ${return_next} ]]; then
      if [[ ${arg} == -* ]]; then
        echo "Invalid parameter for argument: ${*} <param>, got: '${arg}'" >&2
        exit 2
      fi
      echo "${arg}"
      return
    fi
    if list-in "${arg}" "${@}"; then
      return_next=1
      continue
    fi
  done
  if [[ -n ${return_next} ]]; then
    echo "Missing required parameter for argument: ${*} <param>" >&2
    exit 2
  fi
}
