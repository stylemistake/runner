# argparse.sh
## Unit tests

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
