_runner_completions() {
    local -a options=('-C' '-f' '-l' '-h' '--directory=' '--file='
        '--list-tasks' '--help')
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local flag tasks
    ## Complete the short directory option
    if [[ ${prev} == '-C' ]]; then
        compopt -o dirnames
        COMPREPLY=()
        return 0
    fi
    ## Complete the short file option
    if [[ ${prev} == '-f' ]]; then
        COMPREPLY=()
        return 0
    fi
    ## Shift compwords to feed into the next condition
    if [[ ${prev} == '--'* && ${cur} == '=' ]]; then
        flag="${prev}"
        prev="${cur}"
        cur=""
    fi
    ## Complete long options
    if [[ ${prev} == '=' ]]; then
        [[ -z ${flag} ]] && flag="${COMP_WORDS[COMP_CWORD-2]}"
        ## Limit selection to directories
        if [[ ${flag} == '--directory' ]]; then
            compopt -o dirnames
        fi
        ## Show file completions (using -o default)
        COMPREPLY=()
        return 0
    fi
    ## Complete all options
    if [[ ${cur} == '-'* ]]; then
        COMPREPLY=($(compgen -W "${options[*]}" -- "${cur}"))
        [[ ${#COMPREPLY[@]} == 1 && ${COMPREPLY[0]} != "--"*"=" ]] \
            && compopt +o nospace || compopt -o nospace
        return 0
    fi
    ## NOTE: ${COMP_WORDS[@]:1} provides the context of currently entered
    ## options, so runner would know what runnerfile to use.
    tasks="$(runner -l ${COMP_WORDS[@]:1})"
    if [[ ${?} -ne 0 ]]; then
        ## Show nothing at all
        compopt +o default
        COMPREPLY=()
        return 0
    fi
    ## Complete task names
    COMPREPLY=($(compgen -W "${tasks}" -- "${cur}"))
}

complete -o default -F _runner_completions runner
