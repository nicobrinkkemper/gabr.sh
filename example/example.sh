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
if [ $# -ne 0 ]; then
    declare usageFiles="" # disable file listing
fi