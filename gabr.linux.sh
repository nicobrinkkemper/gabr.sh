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
    FUNCNEST=50
    if ! [[ -v fn ]]; then
        local fn
    fi
    if ! [[ -v args ]]; then
        local -a args=()
    fi
    if ! [[ -v debug ]]; then
        local -a debug=()
    fi
    if ! [[ -v ext ]]; then
        local ext=".sh"
    fi
    if ! [[ -v dir ]]; then
        local dir=.
    fi
    if ! [[ -v env ]]; then
        local env=dev
    fi
    if ! [[ -v default ]]; then
        local default=usage # By default a function called 'usage' prints a variable called 'usage' through variable expansion
    fi
    if ! [[ -v root ]]; then
        local root=$PWD
    fi
    # Set from globals
    if [[ -v GABR_ROOT ]]; then
        root=$GABR_ROOT # Optionally set a fixed root through a global
    fi
    if [[ -v GABR_ENV ]]; then
        env=$GABR_ENV
    fi
    if [[ -v GABR_DEFAULT ]]; then
        default=$GABR_DEFAULT # Optionally set a fixed namespace for 'usage' functionality
    fi
    # prod mode
    if [[ $env = prod ]]; then
        set -eEuo pipefail # this will crash terminal on error
    fi
    # debug mode
    if [[ $env = debug ]] && ! [[ -v debug ]]; then
        debug=(fn args dir)
    fi
    # usage
    if ! [[ -v usage ]]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    if ! [[ $default = usage ]]; then
        default="$(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]")" # should be save for eval, unless you're a wizard
        if ! [[ -v default ]]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "default may only contain [:alnum:], [:upper:], [:lower:]" 1>&2
            return 1
        fi
        if ! [[ -v $default ]]; then
            local $default="$usage"
        fi
    fi
    # arguments
    if [[ $# -eq 0 ]]; then
        if ! [[ ${#args[@]} -eq 0 ]]; then
            set -- ${args[@]:-}
        else
            set -- $default
        fi
    fi
( # @enter subshell
    local IFS=$'\n\t'
    if [[ $env = dev ]] || [[ $env = debug ]]; then
        set -Euo pipefail
    fi
    trap '(exit $?); return $?' ERR SIGINT
    if ! [[ $default = usage  ]] && ! [[ $(type -t $default) = function ]]; then
        source /dev/stdin << EOF
function $default() {
    echo "${!default}"
}
EOF
    elif ! [[ $(type -t usage) = function ]]; then
        function usage() {
            echo $usage
        }
    fi
    while ! [[ $# -eq 0 ]]
    do
        fn=${1:-$default}
        shift
        args=(${@})
        if [[ -v debug ]]; then
            echo "# -----------" >&2
            for val in ${debug[@]}
            do
                local valArr=${val}[@]
                if [[ -v $val ]] || [[ -n ${!valArr+set} ]]; then
                    printf "# "%s'\n' "# $(declare -p $val 2>/dev/null | cut -d' ' -f 3-)" >&2
                fi
            done
        fi
        if [[ ${fn::1} = '-' ]]; then
            break
        elif [[ $(type -t ${fn}) = function ]]; then
            if [[ -v debug ]]; then
                printf "# "%s'\n' "Calling ${@}" >&2
            fi
            cd $dir
            dir=.
            ${fn} ${@};
            break
        elif [[ -f ${dir}/$fn ]]; then # allow files in dir
            . ${dir}/$fn
            [[ $(type -t ${fn}) = function ]] && set -- $fn ${@}
        elif [[ -f ${dir}/${fn}${ext} ]]; then # allow files in dir omitting extension
            . ${dir}/${fn}${ext}
            [[ $(type -t ${fn}) = function ]] && set -- $fn ${@}
        elif [[ -d ${dir}/$fn ]]; then # allow new directory
            dir+=/$fn
            [[ -f ${dir}/$fn ]] || [[ -f ${dir}/${fn}${ext} ]] && set -- $fn ${@}
        elif ! [[ ${dir:0:${#root}} = $root ]]; then # allow root directory
            dir=$root
            [[ -f ${dir}/$fn ]] || [[ -f ${dir}/${fn}${ext} ]] && set -- $fn ${@}
        else
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "'$fn' could not be used as file or function" 1>&2
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