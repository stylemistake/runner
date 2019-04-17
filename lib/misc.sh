## misc.sh
## Various utility functions
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

get-arch() {
  uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/
}

is-defined() {
  hash "${@}" 2>/dev/null
}

## Finds and prints the path to program. Exits if it couldn't find one.
## Usage: find-executable-or-die [<program_name_1> ...]
find-executable-or-die() {
  local path_to_bin
  path_to_bin="$(command -v "${@}" | head -1)"
  if [[ -z ${path_to_bin} ]]; then
    echo "Could not find '${1}', aborting..."
    exit 1
  fi
  echo "Found: ${path_to_bin}" >&2
  echo "${path_to_bin}"
}

## Compare timestamp of target file to source files/dirs
## Usage: ${0} -i [-d <source_dir> ...] [-f <source_file> ...]
##             -o [-d <target_dir> ...] [-f <target_file> ...]
##   0 (ok)   - source is newer than target
##   1 (fail) - source is older than target
file-compare() {
  ## Path type and comparison mode
  local path_mode
  local path_type
  ## Best sources and targets for comparison
  local best_source
  local best_target
  ## Set shell options
  shell-opts-push
  shopt -s globstar
  ## Iterate over arguments
  while [[ ${#} -ne 0 ]]; do
    ## Read mode flags
    if [[ ${1} == "-i" || ${1} == "-o" ]]; then
      path_mode="${1}"
      shift 1
      continue
    fi
    if [[ ${1} == "-d" || ${1} == "-f" ]]; then
      path_type="${1}"
      shift 1
      continue
    fi
    if [[ ${1} == -* ]]; then
      logger-log -w "Unrecognized option: ${1}"
      shift 1
      continue
    fi
    ## Ensure that flags were set before accepting files
    if [[ -z ${path_mode} ]]; then
      logger-log -e "Expected '-i/-o' flag before a file argument."
      return 2
    fi
    if [[ -z ${path_type} ]]; then
      logger-log -e "Expected '-d/-f' flag before a file argument."
      return 2
    fi
    ## Start comparing
    ## Get path for inspection
    local path="${1}"
    shift 1
    ## The path is a single file
    if [[ ${path_type} == "-f" ]]; then
      local file="${path}"
      ## Compare to best source
      if [[ ${path_mode} == "-i" && -e ${file} ]]; then
        if [[ ${file} -nt "${best_source}" ]]; then
          ## Set the new best source
          best_source="${file}"
        fi
        continue
      fi
      ## Compare to best target
      if [[ ${path_mode} == "-o" && -e ${file} ]]; then
        if [[ -z ${best_target} || ${file} -ot "${best_target}" ]]; then
          ## Set the new best target
          best_target="${file}"
        fi
        continue
      fi
      continue
    fi
    ## The candidate is a directory
    if [[ ${path_type} == "-d" ]]; then
      ## Compare all files within directory
      local file
      for file in "${path}"/**; do
        ## Compare to best source
        if [[ ${path_mode} == "-i" && -f ${file} ]]; then
          if [[ ${file} -nt "${best_source}" ]]; then
            ## Set the new best source
            best_source="${file}"
          fi
          continue
        fi
        ## Compare to best target
        if [[ ${path_mode} == "-o" && -f ${file} ]]; then
          if [[ -z ${best_target} || ${file} -ot "${best_target}" ]]; then
            ## Set the new best target
            best_target="${file}"
          fi
          continue
        fi
      done
      continue
    fi
  done
  ## Restore shell options
  shell-opts-pop
  ## Handle a special case when there was no source provided
  if [[ -z ${best_source} ]]; then
    ## Return 1 if there is some target
    ## i.e. target is ok by itself and doesn't need rebuild
    if [[ -n ${best_target} ]]; then
      return 1
    fi
    ## Return 0 if there is no target
    ## i.e. always build whatever has no inputs or outputs
    return 0
  fi
  ## Do a final comparison of best candidates
  if [[ ${best_source} -nt ${best_target} ]]; then
    return 0
  fi
  return 1
}

ask-confirm() {
  if [[ ! -t 1 ]]; then
    logger-log -w "Not an interactive shell, skipping..."
    return 1
  fi
  local response
  read -r -p "${*} [y/N] " response
  if [[ "$response" =~ ^(yes|y|Yes|Y)$ ]]; then
    return 0
  fi
  return 1
}
