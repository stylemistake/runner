## colorize.sh
## Color definitions and colorize function
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

color_black="$(echo -e '\x1b[30m')"
color_red="$(echo -e '\x1b[31m')"
color_green="$(echo -e '\x1b[32m')"
color_yellow="$(echo -e '\x1b[33m')"
color_blue="$(echo -e '\x1b[34m')"
color_purple="$(echo -e '\x1b[35m')"
color_cyan="$(echo -e '\x1b[36m')"
color_grey="$(echo -e '\x1b[90m')"
color_light_grey="$(echo -e '\x1b[37m')"
color_light_red="$(echo -e '\x1b[91m')"
color_light_green="$(echo -e '\x1b[92m')"
color_light_yellow="$(echo -e '\x1b[93m')"
color_light_blue="$(echo -e '\x1b[94m')"
color_light_purple="$(echo -e '\x1b[95m')"
color_light_cyan="$(echo -e '\x1b[96m')"
color_white="$(echo -e '\x1b[97m')"
color_bold="$(echo -e '\x1b[1m')"
color_reset_bold="$(echo -e '\x1b[0m')"
color_reset="$(echo -e '\x1b[0m')"

colorize() {
  local color
  local bold
  local result
  for ((;;)); do
    if [[ ${#} -eq 0 ]]; then
      break
    fi
    if [[ ${1} == "-c" ]]; then
      shift 1
      if [[ ${1} == "black" ]]; then
        color="${color_black}"
      elif [[ ${1} == "red" ]]; then
        color="${color_red}"
      elif [[ ${1} == "green" ]]; then
        color="${color_green}"
      elif [[ ${1} == "yellow" ]]; then
        color="${color_yellow}"
      elif [[ ${1} == "blue" ]]; then
        color="${color_blue}"
      elif [[ ${1} == "purple" ]]; then
        color="${color_purple}"
      elif [[ ${1} == "cyan" ]]; then
        color="${color_cyan}"
      elif [[ ${1} == "grey" ]]; then
        color="${color_grey}"
      elif [[ ${1} == "light-grey" ]]; then
        color="${color_light_grey}"
      elif [[ ${1} == "light-red" ]]; then
        color="${color_light_red}"
      elif [[ ${1} == "light-green" ]]; then
        color="${color_light_green}"
      elif [[ ${1} == "light-yellow" ]]; then
        color="${color_light_yellow}"
      elif [[ ${1} == "light-blue" ]]; then
        color="${color_light_blue}"
      elif [[ ${1} == "light-purple" ]]; then
        color="${color_light_purple}"
      elif [[ ${1} == "light-cyan" ]]; then
        color="${color_light_cyan}"
      elif [[ ${1} == "white" ]]; then
        color="${color_white}"
      fi
      shift 1
      continue
    fi
    if [[ ${1} == "-b" ]]; then
      shift 1
      bold="${color_bold}"
      continue
    fi
    if [[ ${1} == "+b" ]]; then
      shift 1
      bold="${color_reset_bold}"
      continue
    fi
    if [[ ${1} == "-r" ]]; then
      shift 1
      ## Append the reset character
      result+="${color_reset}"
      ## Reset color state
      color=""
      bold=""
      continue
    fi
    local str="${1}"
    shift 1
    ## Replace reset characters with our current color state.
    str="${str//${color_reset}/${color_reset}${bold}${color}}"
    ## Append the string
    result+="${bold}${color}${str}"
  done
  ## Append the reset character
  result+="${color_reset}"
  ## Print the final string
  echo "${result}"
}
