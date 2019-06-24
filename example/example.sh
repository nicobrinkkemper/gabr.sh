#!/usr/bin/env bash
# @file example.sh
#
# @brief  [example.sh](./example.sh) adds some variables for [usage.sh](./usage.sh) whenever the argument `example` is given.
#
# @example
#   $ gabr example human
#   Usage: gabr example human [cry|laugh|smile|stare]
#   

declare stack="$(declare -f -F)" # start keeping count of stack (usage.sh will do difference check)
if [ $# -eq 0 ]; then
    set -- usage
fi
if ! [ "${1:-usage}" = 'usage' ]; then
    declare usageFiles="" # disable file listing
fi