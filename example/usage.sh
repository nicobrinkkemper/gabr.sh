#!/usr/bin/env bash
# @file usage.sh
#
# @brief  Usage.sh contains a example on how to reimplement the usage behavior of gabr.
usage() {
    local stack="${stack:-$(declare -F)}"
    local fullCommand="gabr example"
    local -a bashsource=(${BASH_SOURCE[@]} ${prevArgs[@]})
    echo "Usage: \
${prevArgs[@]:0:$(( ${#prevArgs[@]} - 2 ))}\
$(_usageFiles)\
$(_usageScope)\
${example:-}" >&2
}

function _filename(){
    local filename=${1:-$BASH_SOURCE}
    local pathJuggle=${filename##*/};
    echo ${pathJuggle%%.*}
}

function _usageScope(){ # Prints all functions added to scope by gabr
    if ! [ "${usageScope+set}" = "set" ]; then
        set +x
        local usageScope=$(
            echo "${stack}" "${stack}" "$(declare -F)" |
                tr ' ' '\n' |
                sort        |
                uniq -u     |
                awk '! /^_/{print $0}' | # hide underscore prefixed
                tr '\n' "|"
        );
        if [ -n "${GABR_DEBUG_MODE:-}" ]; then
            set -x
        fi
        if [ -n "${usageScope:-}" ] && [ ${#usageScope} -gt 1 ]; then
            usageScope=" [${usageScope:0: -1}]"
        fi
    fi
    echo "${usageScope:-}"
}

function _usageFiles(){
    if ! [ "${usageFiles+set}" = "set" ]; then
        local findString=""
        for file in ${bashsource[@]} ${BASH_SOURCE[@]}
        do
            findString+="! -name $(_filename ${file})${ext:-.sh} "
        done
        local usageFiles=$(
            IFS=' '
            ! find . -maxdepth 1 ${findString} -name '*'${ext:-.sh} |
                cut -c3- | # cut ./
                rev      | 
                cut -c4- | # cut .sh
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