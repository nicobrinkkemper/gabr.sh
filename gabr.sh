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
    if [ -z "${args:-}" ]; then
        local -a args=()
    elif [ $# -eq 0 ]; then
        set -- ${args[@]:-}
    fi
    if [ -z "${debug[@]:-}" ]; then
        local -a debug=()
    fi
    if [ -z "${fn:-}" ]; then
        local fn
    fi
    if [ -z "${dir:-}" ]; then
        local dir=.
    fi
    if [ -z "${env:-}" ]; then
        local env=dev
    fi
    if [ -z "${pwd:-}" ]; then
        local pwd="${PWD}"
    fi
    if [ -z "${default:-}" ]; then
        local default=usage
    fi
    if [ -z "${root:-}" ]; then
        local root=$PWD
    fi
    # Set from globals
    if [ -n "${GABR_ROOT:-}" ]; then
        root=${GABR_ROOT:-} # Optionally set a fixed root through a global
    fi
    if [ -n "${GABR_ENV:-}" ]; then
        env=${GABR_ENV:-}
    fi
    if [ -n "${GABR_DEFAULT:-}" ]; then
        default=${GABR_DEFAULT:-} # Optionally set a fixed namespace for 'usage' functionality
    fi
    # portable variable indirection
    if [ -z "${usage:-}" ]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    if ! [ "$default" = 'usage' ]; then
        default="$(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]")" # should be save for eval, unless you're a wizard
        if [ -z "$(eval echo \"\$${default}\")" ]; then
            eval "local ${default}=\"${usage}\""
        fi
    fi
    # Set prod mode
    if [ "$env" = 'prod' ]; then
        set -euo pipefail # this will crash terminal on error
    fi
    # Set debug mode
    if [ "$env" = 'debug' ] && [ -z "${debug:-}" ]; then
        debug=(fn args dir filename)
    fi
( # @enter subshell
    local IFS=$'\n\t'
    if [ "$env" = 'dev' ] || [ "$env" = 'debug' ]; then
        set -eEuo pipefail
    fi
    trap '(exit $?); return $?' ERR SIGINT
    if ! [ "$(type -t ${default})" = 'function' ]; then
        eval "\
${default}(){
    echo \"\${${default}:-}\" >&2
}";
    fi
    if [ "$#" -eq 0 ]; then
        $default
        return;
    fi
    while ! [ "$(type -t ${1})" = 'function' ];
    do
        if [ -n "${debug:-}" ]; then
            echo "# -----------" >&2
        fi
        if [ "$#" -eq 0 ]; then
            local -f _default=${default} # this will fail when default is still not a function somehow
            set -- $_default
        fi
        fn=${1}
        shift
        args=(${@:-})
        if [ "${fn::1}" = '-' ]; then
            break
        elif [ -f "${dir}/${fn}" ]; then # allow files in dir
            . "${dir}/${fn}"
        elif [ -f "${dir}/${fn}.sh" ]; then # allow files omitting .sh
            . "${dir}/${fn}.sh"
        elif [ -d "${dir}/${fn}" ]; then # allow directory
            dir+="/${fn}"
            set -- $fn ${args[@]:-}
        elif ! [ "${dir:0:${#root}}" = "$root" ]; then # allow the same as above, but in root directory
            dir=$root
            set -- $fn ${args[@]:-}
        fi
        if [ -n "${debug:-}" ]; then
            for val in ${debug[@]}
            do
                local valArr=${val:-}[@]
                if [ -n "${!valArr:-}" ]; then
                    printf "# "%s'\n' "$(declare -p $val 2>/dev/null | cut -d' ' -f 3-)" >&2
                fi
            done
        fi
        if [[ $(type -t ${fn:-}) = function ]]; then
            set -- $fn ${args[@]:-}
        fi
    done
    if [ -n "${debug:-}" ]; then
        printf "# "%s'\n' "Calling ${@}" >&2
    fi
    cd $dir
    dir=.
    $@;
    return;
# @close subshell
)
}
fi
if [ "$0" = "$BASH_SOURCE" ]; then
    declare IFS=$'\n\t'
    gabr ${*}
fi