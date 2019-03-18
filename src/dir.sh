## dir.sh
## Directory traversal functions
## --------------------------------------------------------
##  Copyright (c) 2019 Aleksej Komarov
##  SPDX-License-Identifier: LGPL-3.0-or-later
## --------------------------------------------------------

dir-enter() {
  pushd "${1}" >/dev/null
}

dir-leave() {
  popd >/dev/null
}
