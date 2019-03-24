## annotation.sh
## Unit tests for annotation.sh
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

tests+=(
  test-annotation
)

test-annotation() {
  annotation-declare @test
  annotation-parse annotated-fn handler-fn
}

annotated-fn() {
  @test hello 1 2
  true
}

handler-fn() {
  [[ ${1} == '@test' ]]
  [[ ${2} == 'hello' ]]
  [[ ${3} == '1' ]]
  [[ ${4} == '2' ]]
}
