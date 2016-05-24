#!/usr/bin/env bash

## Expand aliases
shopt -s expand_aliases

## Mac OS X: fallback on homebrew coreutils
## Detecting GNU utils http://stackoverflow.com/a/8748344/319952
if readlink --version > /dev/null 2>&1 ; then
    alias runner_readlink="readlink"
else
    alias runner_readlink="greadlink"
fi

## Resolve the absolute path to the source folder
if [[ "${FUNCNAME[0]}" == source ]]; then
    runner_src_dir="$(dirname "$(runner_readlink -f "${BASH_SOURCE[0]}")")/src"
else
    runner_src_dir="$(dirname "$(runner_readlink -f "${0}")")/src"
fi

## Include core files
# shellcheck source=src/runner.sh
source "${runner_src_dir}/runner.sh"

## Include CLI specific files
if [[ "${FUNCNAME[0]}" != source ]]; then
    # shellcheck source=src/cli.sh
    source "${runner_src_dir}/cli.sh"
fi
