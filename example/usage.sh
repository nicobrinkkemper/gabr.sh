#!/usr/bin/env bash
# @file usage.sh
#
# @brief  Usage.sh contains a example on how to reimplement the usage behavior of gabr.
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ]; then
function _filename(){
    local filename=${1:-$BASH_SOURCE}
    local pathJuggle=${filename##*/};
    echo ${pathJuggle%%.*}
}
set +x
if ! [[ -v stack ]]; then
    declare stack=$(declare -F)
fi
if [[ $env = debug ]]; then
    set -x
fi
function _usageScope(){ # Prints all functions added to scope by gabr
    if ! [[ -v usageScope ]]; then
        set +x
        local usageScope=$(
            echo "${stack}" "${stack}" "$(declare -F)" |
                tr ' ' '\n' |
                sort        |
                uniq -u     |
                awk '! /^_/{print $0}' | # hide underscore prefixed
                tr '\n' "|"
        );
        if [[ $env = debug ]]; then
            set -x
        fi
        if [[ -v usageScope ]] && [[ ${#usageScope} -gt 1 ]]; then
            usageScope=" [${usageScope:0: -1}]"
        fi
    fi
    echo "${usageScope:-}"
}

function _usageFiles(){
    if ! [[ -v usageFiles ]]; then
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
        if [[ -v usageFiles ]] && [[ ${#usageFiles} -gt 1 ]]; then
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
else
    echo "To use ${BASH_SOURCE}, please update Bash to 4.3+" 1>&2
    return
fi