#!/bin/bash
cd `dirname ${0}`
source ../src/runner.sh

alias parallel=runner_parallel
alias sequence=runner_sequence

source runnerfile.sh
