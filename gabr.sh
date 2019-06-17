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
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ] && [[ -r "${BASH_SOURCE}.linux" || -r "${BASH_SOURCE%\.sh*}.linux.sh" ]]; then
    . "${BASH_SOURCE%\.sh*}.linux$([ "${BASH_SOURCE}" != "${BASH_SOURCE%\.sh*}" ] && echo .sh)"
else
function gabr() {  # A function to run other functions 
    local FUNCNEST=50
    if [ -z "${fullCommand:-}" ]; then
        local fullCommand="$FUNCNAME ${@}"
    fi
    if [ -z "${fn:-}" ]; then
        local fn
    fi
    if [ -z "${file:-}" ]; then
        local file
    fi
    if [ -z "${args:-}" ]; then
        local -a args=()
    fi
    if [ -z "${ext:-}" ]; then
        local ext=".sh"
    fi
    if [ -z "${dir:-}" ]; then
        local dir=.
    fi
    if [ -z "${env:-}" ]; then
        local env=${GABR_ENV:-dev}
    fi
    if [ -z "${default:-}" ]; then
        local default=${GABR_DEFAULT:-usage} # By default a function called 'usage' prints a variable called 'usage' through variable indirection
    fi
    if [ -z "${root:-}" ]; then
        local root=${GABR_ENV:-dev}
    fi
    # Set from globals
    if [ -n "${GABR_ROOT:-}" ]; then
        root=${GABR_ROOT} # Optionally set a fixed root through a global
    fi
    if [ -n "${GABR_ENV:-}" ]; then
        env=${GABR_ENV}
    fi
    if [ -n "${GABR_DEFAULT:-}" ]; then
        default=${GABR_DEFAULT} # Optionally set a fixed namespace for 'usage' functionality
    fi
    # prod mode
    if [ "$env" = 'prod' ]; then
        set -eEuo pipefail # this will crash terminal on error
    fi
    # usage
    if [ -z "${usage:-}" ]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    # customize usage
    if ! [ "$default" = 'usage' ]; then
        if [ -z "${default:-}" ] || ! [ "$default" = "$(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]")" ]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "default may only contain [:alnum:], [:upper:], [:lower:]" 1>&2
            return 1
        fi
        if [ -z "$(declare -p ${default} 2>/dev/null)" ]; then
            local $default="$usage"
        fi
    fi
( # @enter subshell
    # dev mode
    if [ "$env" = 'dev' ]; then
        set -eEuo pipefail
    fi
    # all modes
    if [ "$env" = 'dev' ] || [ "$env" = 'prod' ] || [ "$env" = 'debug' ]; then
        local IFS=$'\n\t'
        trap '(exit $?); return $?' ERR SIGINT
    fi
    # usage
    if ! [ "$default" = 'usage'  ] && ! [ "$(type -t $default)" = 'function' ]; then
        source /dev/stdin << EOF
function $default() {
    echo '${!default}'
}
EOF
    elif ! [ "$(type -t usage)" = 'function' ]; then
        function usage() {
            echo $usage
        }
    fi
    # debug mode
    if [ "$env" = 'debug' ]; then
        set -eExuo pipefail
    fi
    # helpers
    _isFn(){    [ "$(type -t ${fn})" = 'function' ]; }
    _isFile(){  [ -f "${dir}/${fn}${ext}" ] || [ -f "${dir}/${fn}" ]; }
    _isDir(){   [ -d "${dir}/${fn}" ] || [ "${dir:0:${#root}}" = "$root" ]; }
    _setFile(){ file=$([ -f "${dir}/${fn}${ext}" ] && echo "${dir}/${fn}${ext}" || echo "${dir}/${fn}"); }
    _setDir(){  dir=$([ -d "${dir}/${fn}" ] && echo "${dir}/${fn}" || echo "$root"); }
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
        shift
        args=(${@:-})
        if [ "${fn::1}" = '-' ]; then
            break
        elif _isFn; then
            cd $dir
            dir=.
            ${fn} ${@:-};
            break
        elif _isFile; then # allow files in dir
            _setFile
            . $file
            _isFn && set -- $fn ${@:-} && continue
            [ $# -eq 0 ] && break # Allow sourcing files without calling a function
        elif _isDir; then # allow directory
            _setDir
            _isFile && set -- $fn ${@:-} && continue
        fi
        if [ $# -eq 0 ]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "'$fn' could not be used as file, function or directory" 1>&2
            return 1
        fi
    done
    return;
# @close subshell
)
}
fi
if [ "$0" = "$BASH_SOURCE" ]; then
    declare IFS=$'\n\t'
    gabr ${*}
fi