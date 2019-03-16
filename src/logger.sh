## logger.sh
## Logging facilities

## Logs a message
## Usage: ${0} [-adeiw] [<message> ...]
logger-log() {
  if list-includes "${1}" -a --action; then
    shift 1
    echo "$(colorize -b -c light-green "=> " -c white "${*}")" >&2
    return
  fi
  if list-includes "${1}" -e --error; then
    shift 1
    echo "$(colorize -b -c light-red "=> " -c white "${*}")" >&2
    return
  fi
  if list-includes "${1}" -w --warning; then
    shift 1
    echo "$(colorize -b -c light-yellow "=> " -c white "${*}")" >&2
    return
  fi
  if list-includes "${1}" -i --info; then
    shift 1
    echo "$(colorize -b -c light-blue ":: " -c white "${*}")" >&2
    return
  fi
  if list-includes "${1}" -d --debug; then
    shift 1
    echo "$(colorize -c grey "${*}")" >&2
    return
  fi
  echo "${*}" >&2
}

## Prints and executes the passed command
## Usage: ${0} [<command> <arg> ...]
## Note: Do not use this on bash built-ins which are affected by function
## scope, e.g. 'source'.
logger-exec() {
  echo "$(colorize -b -c light-green "=> " +b -c grey "${*}")" >&2
  "${@}"
}
