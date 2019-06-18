#!/usr/bin/env bash
# @file usage.sh
#
# @brief  Usage.sh contains a example on how to reimplement the usage behavior of gabr.
function _filename(){
    local filename=${1:-$BASH_SOURCE}
    local pathJuggle=${filename##*/};
    echo ${pathJuggle%%.*}
}
set +x
declare stack=${stack:-$(declare -F)}
if [ "$env" = 'debug' ]; then
    set -x
fi
function _usageScope(){ # Prints all functions added to scope by gabr
    if [ -z "${usageScope:-}" ]; then
        set +x
        local usageScope=$(
            echo "${stack}" "${stack}" "$(declare -F)" |
                tr ' ' '\n' |
                sort        |
                uniq -u     |
                awk '! /^_/{print $0}' | # hide underscore prefixed
                tr '\n' "|"
        );
        if [ "$env" = 'debug' ]; then
            set -x
        fi
        if [ -n "${usageScope:-}" ] && [ ${#usageScope} -gt 1 ]; then
            usageScope=" [${usageScope:0: -1}]"
        fi
    fi
    echo "${usageScope:-}"
}

function _usageFiles(){
    if [ -z "${usageFiles:-}" ]; then
        local findString=""
        for bashsource in ${BASH_SOURCE[@]}
        do
            findString+="! -name $(_filename ${bashsource})${ext:-.sh} "
        done
        local usageFiles=$(
            IFS=' '
            ! find . -maxdepth 1 ${findString} -name '*'${ext:-.sh} |
                cut -c3- | 
                rev      | 
                cut -c4- | 
                rev      |
                awk '!/^\./{ print $0 }' | # hide dot prefixed
                tr '\n' "|"
            );
        if [ -n "${usageFiles:-}" ] && [ ${#usageFiles} -gt 1 ]; then
            usageFiles=" [${usageFiles:0: -1}]"
        fi
    fi
    echo "${usageFiles:-}"
}
function usage(){
    set +x
    local fullCommand=${fullCommand:-"usage"}
    echo "Usage: \
${fullCommand}\
$(_usageFiles)\
$(_usageScope)\
${example:-}" >&2
}