#!/usr/bin/env bash
# @file example.sh
#
# @brief  [example.md](./example.md) links [usage.md](./usage.md) to a function called `usage`.
#
# @example
#   $ gabr example human
#   Usage: gabr example human [cry|laugh|smile|stare]
#   

declare stack="$(declare -F)" # start keeping count of stack (usage.md will do difference check)
if [ $# -eq 0 ]; then
    set -- usage
else
    declare usageFiles="" # disable file listing
fi