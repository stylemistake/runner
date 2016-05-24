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
runner_src_dir="$(dirname "$(runner_readlink -f ${0})")/src"

## Include core files
source "${runner_src_dir}/runner.sh"

## Include CLI specific files
if [[ "${FUNCNAME[0]}" != source ]]; then
    source "${runner_src_dir}/cli.sh"
fi
