#!/usr/bin/env -S bash

# Uses: https://github.com/jesperhh/qmlfmt
# Can be installed from AUR "qmlfmt-git"
# Requires qt6-5compat

find . -name "*.qml" -print -exec qmlfmt -e -b 120 -t 2 -i 2 -w {} \;
