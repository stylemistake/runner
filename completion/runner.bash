#!/usr/bin/env bash

_runner_completions() {
  ## A list of all available options for 'runner'.
  local -a options=(
    '-C' '-f' '-l' '-h' '--directory=' '--file=' '--list-tasks' '--help'
  )

  ## These variables represent words relative to current cursor position.
  ## To show what I mean, here's the drawing:
  ##
  ## $ runner <foo> <bar>_
  ##          ^     ^    ^- cursor
  ##          |     +------ current (cur)
  ##          +------------ previous (prev)
  ##
  ## Words are separated by spaces. '=', '-', '--' count as separate words.
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  ## Here we will store a name of a long flag.
  local flag
  ## Here we will store task names.
  local tasks

  ## Complete a parameter for the short directory option.
  if [[ ${prev} == '-C' ]]; then
    ## Set current completion mode to 'dirnames'.
    compopt -o dirnames
    ## Since we set a mode, we can return an empty reply, and completion
    ## will fall back to 'dirnames'.
    COMPREPLY=()
    return 0
  fi

  ## Complete a parameter for the short file option.
  if [[ ${prev} == '-f' ]]; then
    ## Look at the bottom of the script, and you will see this:
    ##   complete -o default
    ## This means that if we didn't set any completion mode with 'compopt',
    ## and return an empty reply, it falls back to 'default' mode, which
    ## we have set with 'complete -o default'.
    COMPREPLY=()
    return 0
  fi

  ## Shift COMP_WORDS to feed into the next condition.
  ## It's hard to describe, but basically, when your cursor is right after
  ## the '=' sign, '=' becomes the current word.
  ## When you enter something after '=', it becomes the previous word.
  ## So, to maintain a little bit of consistency here, we shift all words
  ## by one position, so the next 'if' statement can safely assume, that we
  ## are entering the flag parameter and are past the '=' sign.
  if [[ ${prev} == '--'* && ${cur} == '=' ]]; then
    ## Store the flag name
    flag="${prev}"
    ## Current becomes previous
    prev="${cur}"
    ## Empty string becomes current
    cur=""
  fi

  ## Complete a parameter for the long option.
  if [[ ${prev} == '=' ]]; then
    ## Remember that we have set the flag in the previous 'if' statement?
    ## Guess what, if that statement didn't run, we don't have the 'flag'
    ## variable, so we need to fill it up!
    [[ -z ${flag} ]] && flag="${COMP_WORDS[COMP_CWORD-2]}"
    ## Set completion mode to 'dirnames'.
    if [[ ${flag} == '--directory' ]]; then
      compopt -o dirnames
    fi
    ## If we didn't set any completion mode, it falls back to 'default',
    ## which we have set with 'complete -o default'.
    ## Empty reply tells bash to use this completion mode.
    COMPREPLY=()
    return 0
  fi

  ## Complete all (long/short) option names.
  if [[ ${cur} == '-'* ]]; then
    ## Generate a completion reply based on available option names and
    ## currently entered word.
    COMPREPLY=($(compgen -W "${options[*]}" -- "${cur}"))
    ## Ff COMPREPLY has a long option with '=' sign, we shouldn't put
    ## space after it. I know, this is a weird lookin' one-liner. :)
    [[ ${#COMPREPLY[@]} == 1 && ${COMPREPLY[0]} != "--"*"=" ]] \
      && compopt +o nospace || compopt -o nospace
    return 0
  fi

  ## Get a task list from the runner.
  ## NOTE: ${COMP_WORDS[@]:1} is a list of currently entered options,
  ## so we provide it to the runner, so that runner would know, which
  ## directory should it enter and what runnerfile should it use.
  tasks="$(runner -l ${COMP_WORDS[@]:1})"

  ## Errors must be ignored
  if [[ ${?} -ne 0 ]]; then
    ## Switch off the 'default' completion mode we set using
    ## 'complete -o default'.
    compopt +o default
    ## Empty reply stands for no reply, because there's no mode to fall
    ## back on.
    COMPREPLY=()
    return 0
  fi

  ## Complete task names
  COMPREPLY=($(compgen -W "${tasks}" -- "${cur}"))
}

## NOTE: 'complete -o <option>' sets an option permanently.
## 'compopt -o <option>' sets an option just for the current completion call,
## and resets back to whatever what set with 'complete -o <option>'.
## NOTE: By the way, 'default' mode isn't enabled by default when using
## 'complete' without any options ('-o' flag).
complete -o default -F _runner_completions runner
