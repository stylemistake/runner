#!/usr/bin/env bash
# set -e
shopt -s globstar

source_files=(bin/runner src/**/*.sh test/**/*.sh runnerfile.sh)
publish_files=(bin completion src LICENSE.md README.md VERSION)

task-default() {
  runner-run-task test
  runner-run-task shellcheck
}

task-shellcheck() {
  logger-exec shellcheck \
    --shell=bash \
    --exclude=SC2164 \
    "${source_files[@]}"
}

task-shellcheck-watch() {
  watch -c -n 5 shellcheck \
    --shell=bash \
    --exclude=SC2164 \
    --color=always \
    "${source_files[@]}"
}

task-test() {
  logger-exec bash test/unit.sh
  logger-exec bash test/worker-model.sh
}

task-readme() {
  doctoc README.md
}

task-distclean() {
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
  # shellcheck disable=SC2016
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
  logger-log "Next version: ${next_tag}"
  ## Write VERSION file
  logger-log "Updating VERSION"
  echo "${next_tag}" > VERSION;
  ## Update package.json
  if hash npm 2>/dev/null; then
    logger-log "Updating package.json"
    runner-enter-dir distrib/npm
    logger-exec npm version "${next_tag}"
    runner-leave-dir
  else
    logger-log -w "Missing 'npm', skipping..."
  fi
}

task-publish-npm() {
  runner-run-task distclean
  rsync -a --relative "${publish_files[@]}" distrib/npm
  runner-enter-dir distrib/npm
  npm publish
  runner-leave-dir
}
