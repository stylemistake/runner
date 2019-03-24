## annotation.sh
## Annotation parser
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

annotation_names=()

## Usage: ${0} <annotation_name>
annotation-declare() {
  local annot="${1}"
  ## Add annotation to the list
  annotation_names+=("${annot}")
  ## Create a stub for this annotation
  eval "${annot}() { return 0; }"
}

## Usage: ${0} <annotated_fn> <handler_fn>
annotation-parse() {
  local annotated_fn="${1}"
  local handler_fn="${2}"
  ## Extract function body
  local fn_body
  fn_body="$(declare -f "${annotated_fn}")"
  ## Iterate over lines
  local line
  local -a line_items
  while read -r line; do
    ## Remove leading whitespace characters
    line="${line#"${line%%[![:space:]]*}"}"
    ## Remove trailing whitespace characters
    line="${line%"${line##*[![:space:]]}"}"
    ## Remove trailing semicolon
    line="${line%"${line##*[!;]}"}"
    ## Read line into array
    read -ra line_items <<< "${line}"
    ## Call annotation handler
    if list-includes annotation_names "${line_items[0]}"; then
      "${handler_fn}" "${line_items[@]}"
    fi
  done <<< "${fn_body}"
}
