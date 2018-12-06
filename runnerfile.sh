#!/usr/bin/env bash

source_files=(bin/runner src/*.sh runnerfile.sh)
publish_files=(bin completion src LICENSE.md README.md VERSION)

task-default() {
  @run-tasks -p task-{shellcheck,test}
}

task-shellcheck() {
  @run-command shellcheck --exclude=SC2016,SC2155,SC2164 "${source_files[@]}"
}

task-test() {
  bash test/test.sh >/dev/null
}

task-readme() {
  doctoc README.md
}

task-clean() {
  git clean -dxf
}

task-update-version() {
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
  @log "Next version: ${next_tag}"
  ## Write VERSION file
  @log "Updating VERSION"
  echo "${next_tag}" > VERSION;
  ## Update package.json
  if runner_is_defined npm; then
    @log "Updating package.json"
    @enter-dir distrib/npm
    @run-command npm version "${next_tag}"
    @leave-dir
  else
    @log-warning "Missing 'npm', skipping..."
  fi
}

task-publish-npm() {
  @run-tasks task-clean
  rsync -a --relative "${publish_files[@]}" distrib/npm
  @enter-dir distrib/npm
  npm publish || return "${?}"
  @leave-dir
}
