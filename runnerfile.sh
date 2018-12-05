#!/usr/bin/env bash

source_files=(bin/runner src/*.sh runnerfile.sh)
publish_files=(bin completion src LICENSE.md README.md VERSION)

task_default() {
  runner_parallel shellcheck test
}

task_shellcheck() {
  runner_run shellcheck --exclude=SC2016,SC2155,SC2164 "${source_files[@]}"
}

task_test() {
  bash test/test.sh >/dev/null
}

task_readme() {
  doctoc README.md
}

task_clean() {
  git clean -dxf
}

task_update-version() {
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
    print fields["major"] + 0 "." fields["minor"] "." fields["patch"];
  }'
  local next_tag
  next_tag="$(awk -F '.' "${awk_prog}" < VERSION)"
  runner_log "Next version: ${next_tag}"
  ## Write VERSION file
  runner_log "Updating VERSION"
  echo "${next_tag}" > VERSION;
  ## Update package.json
  if runner_is_defined npm; then
    runner_log "Updating package.json"
    enter-dir distrib/npm
    runner_run npm version "${next_tag}"
    leave-dir
  else
    runner_log_warning "Missing 'npm', skipping..."
  fi
}

task_publish-npm() {
  runner_sequence clean
  rsync -a --relative "${publish_files[@]}" distrib/npm
  enter-dir distrib/npm
  npm publish || return "${?}"
  leave-dir
}


##  Utility functions
## --------------------------------------------------------

dir_stack=()

enter-dir() {
  local path="${1}"
  dir_stack+=("${path}")
  runner_log "Entering '${path}'"
  pushd "${path}" >/dev/null
}

leave-dir() {
  local path="${dir_stack[-1]}"
  unset 'dir_stack[-1]'
  runner_log "Leaving '${path}'"
  popd >/dev/null
}
