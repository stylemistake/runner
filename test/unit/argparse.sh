## argparse.sh
## Unit tests for argparse.sh
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

tests+=(
  test-argparse
)

test-argparse() {
  argparse-parse -Stc --long 123
  argparse-has-args -S -t -c
  argparse-has-args --long
  local param
  param="$(argparse-get-arg-param --long)"
  [[ ${param} == "123" ]]
}
