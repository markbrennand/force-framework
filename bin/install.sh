#!/bin/bash

readonly alias="${1}"
readonly pkg="${2}"

[[ x"${pkg}" = x"" ]] && {
    echo 1>&2 "usage: install.sh alias package"
    exit 1
}

sf package install -o "${alias}" -p "${pkg}" -w 60 -a package
