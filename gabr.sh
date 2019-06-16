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
if [ -n "${debug:-}" ] || [[ ${GABR_ENV:-} = 'debug' ]]; then
    if [ -n "${debug:-}" ]; then
        echo "# debug=(${debug[*]})"
    fi
    echo "# GABR_ENV=${GABR_ENV:-${env:-}}"
    echo "# BASH_SOURCE=${BASH_SOURCE}"
fi
# we can source linux version if available (has minor benefits like file checking)
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ] && [[ -r "${BASH_SOURCE}.linux" || -r "${BASH_SOURCE%\.sh*}.linux.sh" ]]; then
    . "${BASH_SOURCE%\.sh*}.linux$([ "${BASH_SOURCE}" != "${BASH_SOURCE%\.sh*}" ] && echo .sh)"
else
function gabr() {  # A function to run other functions 
    FUNCNEST=50
    if [ -z "${fn:-}" ]; then
        local fn
    fi
    if [ -z "${args:-}" ]; then
        local -a args=()
    fi
    if [ -z "${debug[@]:-}" ]; then
        local -a debug=()
    fi
    if [ -z "${ext:-}" ]; then
        local ext=".sh"
    fi
    if [ -z "${dir:-}" ]; then
        local dir=.
    fi
    if [ -z "${env:-}" ]; then
        local env=dev
    fi
    if [ -z "${default:-}" ]; then
        local default=usage
    fi
    if [ -z "${root:-}" ]; then
        local root=$PWD
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
        set -euo pipefail # this will crash terminal on error
    fi
    # debug mode
    if [ "$env" = 'debug' ] && [ -z "${debug:-}" ]; then
        debug=(fn args dir filename)
    fi
    # usage
    if [ -z "${usage:-}" ]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    if ! [ "$default" = 'usage' ]; then
        # portable variable indirection
        default="$(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]")" # should be save for eval, unless you're a wizard
        if [ -z "${default:-}" ]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "default may only contain [:alnum:], [:upper:], [:lower:]" 1>&2
            return 1
        fi
        if [ -z "$(declare -p ${default} 2>/dev/null)" ]; then
            local $default="$usage"
        fi
    fi
    # arguments
    if [ "$#" -eq 0 ]; then
        if ! [ "${#args[@]}" -eq 0 ]; then
            set -- ${args[@]:-}
        else
            set -- $default
        fi
    fi
( # @enter subshell
    local IFS=$'\n\t'
    if [ "$env" = 'dev' ] || [ "$env" = 'debug' ]; then
        set -eEuo pipefail
    fi
    trap '(exit $?); return $?' ERR SIGINT
    if ! [ "$default" = 'usage'  ] && ! [ "$(type -t $default)" = 'function' ]; then
        source /dev/stdin << EOF
function $default() {
    echo '${!default}'
}
EOF
    elif ! [[ $(type -t usage) = function ]]; then
        function usage() {
            echo $usage
        }
    fi
    while ! [ "$#" -eq 0 ];
    do
        if [ -n "${debug:-}" ]; then
            echo "# -----------" >&2
            for val in ${debug[@]}
            do
                local valArr=${val:-}[@]
                if [ -n "${!valArr:-}" ]; then
                    printf "# "%s'\n' "$(declare -p $val 2>/dev/null | cut -d' ' -f 3-)" >&2
                fi
            done
        fi
        fn=${1}
        shift
        args=(${@:-})
        if [ "${fn::1}" = '-' ]; then
            break
        elif [ "$(type -t ${fn})" = 'function' ]; then
            if [ -n "${debug:-}" ]; then
                printf "# "%s'\n' "Calling ${@:-}" >&2
            fi
            cd $dir
            dir=.
            ${fn} ${@:-};
            break
        elif [ -f "${dir}/${fn}" ]; then # allow files in dir
            . "${dir}/${fn}"
            [ "$(type -t ${fn})" = 'function' ] && set -- $fn ${@:-}
        elif [ -f "${dir}/${fn}${ext}" ]; then # allow files omitting extension
            . "${dir}/${fn}${ext}"
            [ "$(type -t ${fn})" = 'function' ] && set -- $fn ${@:-}
        elif [ -d "${dir}/${fn}" ]; then # allow directory
            dir+="/${fn}"
            [ -f "${dir}/$fn" ] || [ -f "${dir}/${fn}${ext}" ] && set -- $fn ${@:-}
        elif ! [ "${dir:0:${#root}}" = "$root" ]; then # allow the same as above, but in root directory
            dir=$root
            [ -f "${dir}/$fn" ] || [ -f "${dir}/${fn}${ext}" ] && set -- $fn ${@:-}
        else
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