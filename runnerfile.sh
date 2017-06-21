#!/usr/bin/env bash

source_files=(bin/runner src/*.sh)

task_shellcheck() {
    runner_run shellcheck --exclude=SC2155 "${source_files[@]}"
}

task_test() {
    bash test/test.sh >/dev/null
}

task_readme() {
    doctoc README.md
}

task_default() {
    runner_parallel shellcheck test
}
