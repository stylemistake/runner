## colorize.sh
## Color definitions and colorize function
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

color_black="$(echo -e '\e[30m')"
color_red="$(echo -e '\e[31m')"
color_green="$(echo -e '\e[32m')"
color_yellow="$(echo -e '\e[33m')"
color_blue="$(echo -e '\e[34m')"
color_purple="$(echo -e '\e[35m')"
color_cyan="$(echo -e '\e[36m')"
color_grey="$(echo -e '\e[90m')"
color_light_grey="$(echo -e '\e[37m')"
color_light_red="$(echo -e '\e[91m')"
color_light_green="$(echo -e '\e[92m')"
color_light_yellow="$(echo -e '\e[93m')"
color_light_blue="$(echo -e '\e[94m')"
color_light_purple="$(echo -e '\e[95m')"
color_light_cyan="$(echo -e '\e[96m')"
color_white="$(echo -e '\e[97m')"
color_bold="$(echo -e '\e[1m')"
color_reset="$(echo -e '\e[0m')"

colorize() {
  local color
  local bold
  local str
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
      bold="${color_bold}"
      shift 1
      continue
    fi
    if [[ ${1} == "+b" ]]; then
      bold=""
      shift 1
      continue
    fi
    if [[ ${1} == "-r" ]]; then
      echo -n "${color_reset}"
      color=""
      bold=""
      shift 1
      continue
    fi
    str="${1}"
    shift 1
    ## Replace reset characters with our current color state.
    str="${str//${color_reset}/${color_reset}${color}${bold}}"
    ## Print the string
    echo -n "${color}${bold}${str}"
  done
  echo "${color_reset}"
}
