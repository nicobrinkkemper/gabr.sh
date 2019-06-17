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
    local usageFiles="" # this disables usage.md file options
fi

declare stack=$(declare -F) # this enables usage.sh to detect new functions added
function usage(){
    . ${dir:-.}/usage.sh # this loads usage.sh for this folder when needed
    usage
}