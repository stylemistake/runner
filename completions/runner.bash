_runner() {
  COMPREPLY=( $(compgen -W "$(runner -l)" -- "${COMP_WORDS[COMP_CWORD]}") )
}

complete -F _runner runner
