#!/usr/bin/env bash
# @file gabr.linux.sh
# @brief This file contains the leanest `gabr` implementation
# @description The gabr function will be available after sourcing this file.
# This file supports bash 4.3+, this is to add benefit for Linux machines.
# This file is optional. Both `gabr.sh` and `gabr.linux.sh` work as stand-alones.
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
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ]
then
function gabr() {  # A function to run other functions 
    local FUNCNEST=50
    if ! [[ -v fullCommand ]]; then
        local fullCommand="$FUNCNAME ${@}"
    fi
    if ! [[ -v fn ]]; then
        local fn
    fi
    if ! [[ -v file ]]; then
        local file
    fi
    if ! [[ -v args ]]; then
        local -a args=()
    fi
    if ! [[ -v ext ]]; then
        local ext=".sh"
    fi
    if ! [[ -v dir ]]; then
        local dir=.
    fi
    if ! [[ -v env ]]; then
        local env=${GABR_ENV:-dev}
    fi
    if ! [[ -v default ]]; then
        local default=${GABR_DEFAULT:-usage} # By default a function called 'usage' prints a variable called 'usage' through variable indirection
    fi
    if ! [[ -v root ]]; then
        local root=${GABR_ROOT:-${PWD}}
    fi
    # prod mode
    if [[ $env = prod ]]; then
        set -eEuo pipefail # this will crash terminal on error
    fi
    # usage
    if ! [[ -v usage ]]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    # customize usage
    if ! [[ $default = usage ]]; then
        if ! [[ -v default ]] || ! [[ $default = $(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]") ]]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "default may only contain [:alnum:], [:upper:], [:lower:]" 1>&2
            return 1
        fi
        if ! [[ -v $default ]]; then
            local $default="$usage"
        fi
    fi
    # arguments
( # @enter subshell
    if [[ $env = dev ]] || [[ $env = debug ]]; then
        set -eEuo pipefail
        local IFS=$'\n\t'
    fi
    # usage
    if ! [[ $default = usage  ]] && ! [[ $(type -t $default) = function ]]; then
        source /dev/stdin << EOF
function $default() {
    echo '${!default}' >&2
}
EOF
    elif ! [[ $(type -t usage) = function ]]; then
        function usage() {
            echo $usage >&2
        }
    fi
    # helpers
    _isFn(){    [[ $(type -t ${fn}) = function ]]; }
    _isFile(){  [[ -f ${dir}/${fn}${ext} || -f ${dir}/${fn} ]]; }
    _isDir(){   [[ -d ${dir}/${fn} || ${dir:0:${#root}} = $root ]]; }
    _setFile(){ file=$([[ -f ${dir}/${fn}${ext} ]] && echo ${dir}/${fn}${ext} || echo ${dir}/${fn}); }
    _setDir(){  dir=$([[ -d ${dir}/${fn} ]] && echo ${dir}/${fn} || echo $root); }
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
            if [[ $env = debug ]]; then set -x; fi
            cd $dir
            dir=.
            ${fn} ${@:-};
            if [[ $env = debug ]]; then set +x; fi
            break
        elif _isFile; then # allow files in dir
            _setFile
            if [[ $env = debug ]]; then set -x; fi
            . $file
            if [[ $env = debug ]]; then set +x; fi
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
    if [[ $env = dev ]] || [[ $env = prod ]] || [[ $env = debug ]]; then
        set -eEuo pipefail
        declare IFS=$'\n\t'
    fi
    gabr ${*}
fi