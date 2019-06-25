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
    local fn file
    local FUNCNEST=50
    local default=${GABR_DEFAULT:-usage} 
    local dir=.
    local -a args=()
    local -a files=()
    local -a prevArgs=()
    local ext=${GABR_EXT:-'.sh'} 
    # usage
    if [ -z "${usage:-}" ]; then
        local usage="\
${prevArgs[@]} [directory | file] function [arguments] -- A function to call other functions.
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
    if [ -n "${GABR_ROOT:-}" ] && ! [ "$GABR_ROOT" = "$PWD" ]; then
        cd $GABR_ROOT
    fi
    if [ "${GABR_STRICT_MODE:-true}" = 'true' ]; then
        set -eEuo pipefail
        local IFS=$'\n\t'
        trap 'return $?' ERR SIGINT
        GABR_STRICT_MODE="on"
    fi
    ! [ ${#prevArgs[@]} -eq 0 ] && local -a prevArgs=()
    # helpers
    _isFn(){    [ "$(type -t ${1:-$fn})" = 'function' ]; }
    _canSource(){ 
        for _file in ${files[@]:-}; do
            if [ $_file = $file ]; then
                [ $_file = $file ]
            fi
        done
     }
    _isDebug(){ [ -n "${GABR_DEBUG_MODE:-}" ]; }
    _isRoot()( [ "${dir:0:${#root}}" = "$root" ] || [ "$root" = "$PWD" ] && [ "." = "." ]; )
    
    # begin processing arguments
    if [ $# -eq 0 ]; then
        set -- $default
    fi
    while ! [ $# -eq 0 ];
    do
        fn=${1}
        if [ "${fn::1}" = '-' ]; then # disallow a dash
            prevArgs+=($1)
            shift
            if ! [ "${fn}" = '-' ]; then
                printf $'\033[0;91m'"!: "%s$'\033[0m\n' "Illegal flag: ${fn}" 1>&2
            elif ! [ $# -eq 0 ]; then
                printf $'\033[0;91m'"!: "%s$'\033[0m\n' "${@}" 1>&2
            fi
            return 1
        elif _isFn; then # call a function
            prevArgs+=($1)
            shift
            args=(${@:-})
            _isDebug && set -x
            ${fn} ${@:-}; # call the function
            _isDebug && set +x
            break
        elif [ -f "./${fn}${ext}" ]; then # allow a file with extension
            file=${fn}${ext}
            if ! _canSource; then
                set -- '-' "'$file' is already sourced by argument $fn" 1>&2
                continue
            fi
            files+=($file)
            if ! [ -r "${file:-}" ]; then
                set -- '-' "'$file' is not a readable file" 1>&2
                continue
            fi
            prevArgs+=($1)
            shift
            args=(${@:-})
             _isDebug && set -x
            . ${fn}${ext} # source the file
            _isDebug && set +x
            _isFn && set -- $fn ${@:-}
            [ $# -eq 0 ] && set -- ${default} ${prevArgs[@]}
        elif [ -f "./${fn}" ]; then # allow a file without extension
            prevArgs+=($1)
            shift
            args=(${@:-})
            exec ${fn} $@ # execute the file
            break
        elif [ -d "./${fn}" ]; then # allow a directory
            cd ./$fn
            dir=./$fn
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
            _isFn && continue
            printf $'\033[0;91m'"Crash: "%s$'\033[0m\n' "Could not generate default function" 1>&2
            return 1
        elif [ $# -gt 1 ]; then # shift arguments
            prevArgs+=($1)
            shift
        elif [ $# -eq 1 ] && [ -f "./${default}${ext}" ] && [ "${dir: $(( -${#fn}-1 ))}" = "/$fn" ]; then
            prevArgs+=($1)
            set -- ${default:-usage} ${prevArgs[@]}
        elif [ $# -eq 1 ] && ! [ ${#files[@]} -eq 0 ]; then
            set -- '-' "\
'$fn' could not be used to call a function in file(s): $(echo ${!files[@]})"
        elif [ $# -eq 1 ] && [ -n "${dir:-}" ]; then
            set -- '-' "'$fn' could not be used to call a function in directory $dir"
        else
            set -- '-'  "'$fn' could not be used as file, function or directory"
        fi
    done
    return;
) # @close subshell
}
fi
if [ "$0" = "$BASH_SOURCE" ]; then
    gabr ${*}
fi