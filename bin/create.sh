#!/bin/bash

[[ x"${2}" = x"" ]] && {
    readonly alias="${1}"
} || {
    readonly devhub="${2}"
    readonly alias="${2}"
}

[[ x"${alias}" = x"" ]] && {
    echo 1>&2 "usage: create.sh [devhub] alias"
    exit 1
}

[[ x"${devhub}" = x"" ]] && {
    sf org scratch create -a "${alias}" -w 60 -y 30 -m -e developer
} || {
    sf org scratch create -a "${alias}" -v "${devhub}" -w 60 -y 30 -m -e developer
}
