#!/usr/bin/env bash
# @file gabr.sh
# @brief This file contains the most stable `gabr` implementation
# @description  The gabr function will be available after sourcing this file.
# This file supports bash 3.2+, this is to support apple machines.
# This file sources a modern version of the function if applicable.
# This file acts as a function when called as a file.
#
# @example
#   $ gabr [file] function [arguments] -- A function to call other functions  
#
# @arg $1 string A file, directory or function
# @arg $@ any Will be shifted through until a valid function is found
#
# @exitcode 0  If successfull
# @exitcode >0 On failure
#
# we can source linux version if available (has minor benefits like file checking)
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 4 ] && [[ -r "${BASH_SOURCE}.linux" || -r "${BASH_SOURCE%\.sh*}.linux.sh" ]]; then
    . "${BASH_SOURCE%\.sh*}.linux$([ "${BASH_SOURCE}" != "${BASH_SOURCE%\.sh*}" ] && echo .sh)"
else
function gabr() {  # A function to run other functions 
    local FUNCNEST=50
    [ -z "${GABR_STRICT_MODE:-}" ] && local GABR_STRICT_MODE='on'
    [ -z "${GABR_ROOT:-}" ] && local GABR_ROOT=${PWD}
    [ -z "${fullCommand:-}" ] && local fullCommand="$FUNCNAME ${@}" 
    [ -z "${fn:-}" ] && local fn    
    [ -z "${file:-}" ] && local file  
    [ -z "${args:-}" ] && local -a args=()    
    [ -z "${ext:-}" ] && local ext=".sh" 
    [ -z "${dir:-}" ] && local dir
    [ -z "${default:-}" ] && local default=${GABR_DEFAULT:-usage} 
    [ -z "${root:-}" ] && local root
    # usage
    if [ -z "${usage:-}" ]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    # customize usage
    if ! [ "$default" = 'usage' ]; then
        if [ -z "${default:-}" ] || ! [ "[${default}]" = "$(printf '[%q]\n' "${default}")" ]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "default may not contain special characters" 1>&2
            return 1
        fi
        if [ -z "$(declare -p ${default} 2>/dev/null)" ]; then
            local $default="$usage"
        fi
    fi
( # @enter subshell
    if [ "${GABR_STRICT_MODE}" = 'on' ]; then
        set -eEuo pipefail
        local IFS=$'\n\t'
        trap 'return $?' ERR SIGINT
        GABR_STRICT_MODE="already-on"
    fi
    # helpers
    _isFn(){    [ "$(type -t ${fn})" = 'function' ]; }
    _isDebug(){ [[ -n ${GABR_DEBUG_MODE:-} ]]; }
    _isRoot()( [ "${dir:0:${#root}}" = "$root" ] || [ "$root" = "$PWD" ] && [ "$dir" = "." ]; )
    
    # begin processing arguments
    if [ $# -eq 0 ]; then
        if ! [ ${#args[@]} -eq 0 ]; then
            set -- ${args[@]:-}
        else
            set -- $default
        fi
    fi
    while ! [ $# -eq 0 ];
    do
        fn=${1}
        if [ "${fn::1}" = '-' ]; then # disallow dash
            break
        elif _isFn; then # call a function
            shift
            args=(${@:-})
            cd ${dir:-${root:-.}}
            dir=.
            _isDebug && set -x
            ${fn} ${@:-};
            _isDebug && set +x
            break
        elif [ -n "${file:-}" ]; then # source a file
            file=$file
            if ! [ -r "${file:-}" ]; then
                printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "'$file' is not a readable file" 1>&2
                return 1
            fi
            shift
            args=(${@:-})
            _isDebug && set -x
            . $file # source the file
            _isDebug && set -x
            unset file
            _isFn && set -- $fn ${@:-} # continue looking for a function
            ! [[ ${fn} = ${default:-'usage'} ]] && [ $# -eq 0 ] && set -- ${default:-'usage'}
        elif [ -f "${dir:-.}/${fn}${ext}" ]; then # allow files with extension
            file=${dir:-.}/${fn}$ext
        elif [ -f "${dir:-.}/${fn}" ]; then # allow files without extension
            file=${dir:-.}/$fn
        elif [ -d "${dir:-.}/${fn}" ]; then # allow directory
            dir=${dir:-.}/$fn
        elif [ -f "${root:-${GABR_ROOT}}/${fn}${ext}" ]; then # allow files with extension
            root=${root:-${GABR_ROOT}}
            file=${root:-${GABR_ROOT}}/${fn}$ext
        elif [ -f "${root:-${GABR_ROOT}}/${fn}" ]; then # allow files without extension
            root=${root:-${GABR_ROOT}}
            file=${root:-${GABR_ROOT}}/$fn
        elif [ -d "${root:-${GABR_ROOT}}/${fn}" ]; then # allow directory
            root=${root:-${GABR_ROOT}}/$fn
        elif [ "${fn}" = 'usage' ]; then # allow generated usage function
            usage() {
                echo $usage >&2
            }
        elif [ "${fn}" = "${default}" ]; then # allow generated default function
            source /dev/stdin << EOF
$default() {
    echo '${!default}' >&2
}
EOF
        elif [ $# -eq 1 ] && [ -n "${dir:-}${root:-}" ]; then
            set -- ${default:-usage}
        else
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "'$fn' could not be used as file, function or directory" 1>&2
            return 1
        fi
    done
    return;
) # @close subshell
}
fi
if [ "$0" = "$BASH_SOURCE" ]; then
    gabr ${*}
fi