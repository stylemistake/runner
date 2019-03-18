## time.sh
## Functions for working with time and date

## Alias for GNU date
time-gnu-date() {
  date "${@}"
}

## Returns a unix timestamp in seconds
time-unix() {
  time-gnu-date "+%s"
}

## Returns a unix timestamp in milliseconds
if [[ -n ${EPOCHREALTIME} ]]; then
  ## Use a bash magic variable which returns unix time in microseconds
  ## as a floating point.
  time-unix-ms() {
    local time="${EPOCHREALTIME/./}"
    echo "${time::-3}"
  }
else
  ## Use GNU date from coreutils
  time-unix-ms() {
    time-gnu-date "+%s%3N"
  }
fi

## Returns a human readable duration in milliseconds
## Usage: ${0} <time_ms>
time-pretty-ms() {
  local -i ms="${1}"
  local result
  ## If zero or nothing
  if [[ -z ${ms} || ${ms} -lt 1 ]]; then
    echo "0 ms"
    return
  ## Only ms
  elif [[ ${ms} -lt 1000 ]]; then
    echo "${ms} ms"
    return
  ## Only seconds with trimmed ms point
  elif [[ ${ms} -lt 60000 ]]; then
    result=$((ms / 1000 % 60)).$((ms % 1000))
    echo "${result:0:4} s"
    return
  fi
  local -i parsed
  ## Days
  parsed=$((ms / 86400000))
  [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} d"
  ## Hours
  parsed=$((ms / 3600000 % 24))
  [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} h"
  ## Minutes
  parsed=$((ms / 60000 % 60))
  [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} m"
  ## Seconds
  parsed=$((ms / 1000 % 60))
  [[ ${parsed} -gt 0 ]] && result="${result} ${parsed} s"
  ## Output result
  echo "${result}"
}

## Fallbacks for GNU date
## Detecting GNU coreutils http://stackoverflow.com/a/8748344/319952
if ! date --version >/dev/null 2>&1; then
  if hash gdate 2>/dev/null; then
    time-gnu-date() {
      gdate
    }
  else
    time-unix-ms() {
      time-gnu-date +%s000
    }
  fi
fi
