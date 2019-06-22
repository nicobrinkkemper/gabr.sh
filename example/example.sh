#!/usr/bin/env bash
# @file example.sh
#
# @brief  [example.md](./example.md) links [usage.md](./usage.md) to a function called `usage`.
#
# @example
#   $ gabr example human
#   Usage: gabr example human [cry|laugh|smile|stare]
#   

declare stack="$(declare -f -F)" # start keeping count of stack (usage.md will do difference check)
if [ $# -eq 0 ]; then
    set -- usage
fi
if ! [ "${1:-usage}" = 'usage' ]; then
    declare usageFiles="" # disable file listing
fi