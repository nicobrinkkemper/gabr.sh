#!/usr/bin/env bash
# @file example.sh
#
# @brief  [example.md](./example.md) links [usage.md](./usage.md) to a function called `usage`.
#
# @example
#   $ gabr example human
#   Usage: gabr example human [cry|laugh|smile|stare]
#   
if [ $# -eq 0 ]; then
    set -- usage
else
    declare usageFiles="" # this disables usage.md file options
fi
. ${dir:-}/usage.sh