#!/usr/bin/env bash

source_files=(bin/runner src/*.sh runnerfile.sh)

task_shellcheck() {
    runner_run shellcheck --exclude=SC2155,SC2016 "${source_files[@]}"
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

task_update_version() {
    # $1 should be "--major", "--minor", or "--patch"
    local level="patch"
    case "${1}" in
      --major) level="major" ;;
      --minor) level="minor" ;;
      --patch) level="patch" ;;
    esac
    local awk_prog='{
      fields["major"]=$1;
      fields["minor"]=$2;
      fields["patch"]=$3;
      fields["'${level}'"]++;
    } END {
      print "v" fields["major"] + 0 "." fields["minor"] "." fields["patch"];
    }'
    local next_tag
    next_tag="$(awk -F '.' "${awk_prog}" < VERSION)"
    runner_log "Updating to: ${next_tag}"
    echo "${next_tag}" > VERSION;
}
