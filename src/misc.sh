# misc.sh
## This file includes functions we couldn't move to other modules
## but which have utility value.

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
  if [[ -z path_to_bin ]]; then
    echo "Could not find '${1}', aborting..."
    exit 1
  fi
  echo "Found: ${path_to_bin}" >&2
  echo "${path_to_bin}"
}

## Compare timestamp of target file to source files/dirs
## Usage: needs-rebuild <target> [-d <source_dir> ...] [-f <source_file> ...]
##   0 (ok)   - Target is older, needs rebuild
##   1 (fail) - Target is newer, skip
needs-rebuild() {
  local target="${1}"
  local flag
  shift 1
  if [[ ! -e ${target} ]]; then
    return 0
  fi
  while [[ ${#} -ne 0 ]]; do
    if [[ ${1} == -* ]]; then
      local flag="${1}"
      shift 1
      continue
    fi
    if ! has-any "${flag}" "-d" "-f"; then
      echo "${0}: expected '-d' or '-f' flag."
      exit 1
    fi
    local source="${1}"
    shift 1
    if [[ ${flag} == "-d" ]]; then
      local files_newer="$(find "${source}" -type f -newer "${target}")"
      if [[ -n ${files_newer} ]]; then
        return 0
      fi
      continue
    fi
    if [[ ${flag} == "-f" ]]; then
      if [[ ${source} -nt ${target} ]]; then
        return 0
      fi
      continue
    fi
  done
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
