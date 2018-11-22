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

task_update_version() {
    # $1 should be "--major", "--minor", or "--patch"
    declare level="";
    case $1 in
      --major) level=major;;
      --minor) level=minor;;
      --patch) level=patch;;
    esac

    next_tag="$(
      cat VERSION | awk -F '.' '{
        fields["major"]=$1;
        fields["minor"]=$2;
        fields["patch"]=$3;
        fields["'$level'"]++;
      } END {
        print "v" fields["major"] + 0 "." fields["minor"] "." fields["patch"];
      }'
    )"

    git tag "$next_tag";
    echo "$next_tag" > VERSION;
}
