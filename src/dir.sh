## dir.sh
## Directory traversal functions

dir-enter() {
  pushd "${1}" >/dev/null
}

dir-leave() {
  popd >/dev/null
}
