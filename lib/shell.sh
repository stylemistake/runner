## shell.sh
## Functions for manipulating the state of bash shell
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

shell_opts_stack=()

shell-opts-push() {
  local opts
  opts="$(set +o); set -${-}"
  shell_opts_stack+=("${opts}")
}

shell-opts-pop() {
  local opts="${shell_opts_stack[*]: -1}"
  local stack_len="${#shell_opts_stack[@]}"
  unset "shell_opts_stack[${stack_len}-1]"
  eval "${opts}"
}
