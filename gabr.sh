#!/usr/bin/env bash
# @file gabr.sh
# @brief This file contains one function and acts as that function when called as a file.
# @description  The gabr function will be available after sourcing this file.
# Tt sources a more modern version of the function if BASH_VERSION is 4.3+
# Fear not, these files behave almost identical.
#
# @example
#   $ gabr example human smile
#   This is human
#   :)
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
if [ ${BASH_VERSION:0:1} -eq 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ] && [ -r "${BASH_SOURCE%\.sh*}.linux.sh" ]
then
  . "${BASH_SOURCE%\.sh*}.linux.sh" # we can source linux instead (which has minor benefits like file checking)
else
function gabr() {  # A function to run other functions 
    FUNCNEST=50
    if [ -z "${funcname:-}" ]; then
        local -a funcname=(${FUNCNAME[@]})
    fi
    if [ -z "${filename:-}" ]; then
        local filename
    fi
    if [ -z "${file:-}" ]; then
        local file
    fi
    if [ -z "${exitcode:-}" ]; then
        local exitcode
    fi
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
    if [ -z "${primaryFn:-}" ]; then
        local primaryFn=${1:-}
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
    if [ -z "${stack:-}" ]; then
        local stack=$(declare -F)
    fi
    if [ -z "${wrapInfo:-}" ]; then
        local wrapInfo="# "%s'\n'
    fi
    if [ -z "${wrapErr:-}" ]; then
        local wrapErr=$'\033[0;91m'"Warning: "%s$'\033[0m\n' # printfn LightRed with newline -- e.g. printfn ${wrapErr} "something went wrong"
    fi
    if [ -z "${error:-}" ]; then
        local -a error=()
    fi
    # Set from globals
    if [ -n "${GABR_ROOT:-}" ]; then
        root=${GABR_ROOT:-${PWD}} # Optionally set a fixed root through a global
    fi
    if [ -n "${GABR_ENV:-}" ]; then
        env=${GABR_ENV:-dev}
    fi
    if [ -n "${GABR_DEFAULT:-}" ]; then
        default=${GABR_DEFAULT:-usage} # Optionally set a fixed namespace for 'usage' functionality
    fi
    # portable variable indirection
    if [ -z "${usage:-}" ]; then
        local usage="\
${FUNCNAME} [--file] [--derive] [file] function [arguments] -- A function to call other functions
    --file       A full path to a file
    --derive     A filename without extension
    1..N         Performs various checks to derive flags and optimize the API.
                 Flags are optional and not needed in most cases."
    fi
    if ! [ "$default" = 'usage' ]; then
        default="$(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]")" # should be save for eval, unless you're a wizard
        if [ -z "$(eval echo \$${default})" ]; then
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
    trap 'exitcode=$?; (exit $exitcode); return $exitcode' ERR SIGINT
    if ! [ "$(type -t ${default})" = 'function' ]; then
        eval "\
${default}(){
    eval echo \${${default}:-'usage'} >&2
}";
    fi
    if [ "$#" -eq 0 ]; then
        $default
        return;
    fi
    local prevFn=''
    while [ "$#" -ne 0 ];
    do
        if [ -n "${fn:-}" ]; then
            prevFn=$fn
        fi
        fn=${1:-$default}; shift; args=(${@:-});
        if [ -n "${debug:-}" ]; then
            echo "# -----------" >&2
        fi
        if [ "${fn::2}" = '-' ]; then
            break
        elif [ "${fn::2}" = '--' ]; then
            if [ "${fn}" = '--file' ] || [ "${fn}" = '--derive' ]; then
                
                if [ -z "${args:-}"  ]; then
                    error+=("Can not find a file without arguments")
                    printf "$wrapErr" "${error[*]}" 1>&2
                    return 1;
                elif  ! [ -r "${args}" ]; then
                    error+=("File not found: ${args}")
                    printf "$wrapErr" "${error[*]}" 1>&2
                    return 1;
                else
                    prevFn=$fn
                    fn=$1; shift; args=(${@:-});
                    file=${fn##*/}
                    filename=${file%%.*}
                    . $fn # source the file
                    if [ "$(type -t ${filename})" = 'function' ]; then
                        if [ "${prevFn}" = '--derive' ] || [ -z "${args:-}" ] || [ ${args::1} = '-' ]; then
                            if [ -n "${debug:-}" ]; then
                                printf "$wrapInfo" "${fn} is derived" >&2
                            fi
                            set -- ${filename} ${args[@]:-}
                        fi
                    fi
                fi
            fi
        elif [ "$(type -t ${fn:-})" = 'function' ]; then
            if [ -n "${debug:-}" ]; then
                printf "$wrapInfo" "Calling ${fn}" >&2
            fi
            cd $dir
            dir=.
            $fn ${args[@]:-};
            cd $pwd
            return $?
        elif [ -f "$fn" ]; then # allow file
            set -- --file $fn ${args[@]:-}                             
        elif [ -f "${dir}/$fn" ]; then # allow files in dir
            set -- --file ${dir}/$fn ${args[@]:-}
        elif [ -f "${dir}/$fn.sh" ]; then # allow files omitting .sh
            set -- --derive ${dir}/$fn.sh ${args[@]:-}
        elif [ -f  "${dir}/${fn}/$fn.sh" ]; then # allow dir same as file
            set -- --derive ${dir}/${fn}/$fn.sh ${args[@]:-}
            dir+=/$fn 
        elif [ -d "$fn" ]; then # allow directory
            dir+=/$fn
        elif ! [ "$dir" = '.' ]; then # allow the same as above, but in current directory
            dir=.
            set -- $fn ${args[@]:-}
        elif ! [ "$PWD" = "$root" ]; then # allow the same as above, but in root directory
            cd $root
            set -- $fn ${args[@]:-}   
            if [ -n "${debug:-}" ]; then
                printf $wrapInfo "Nothing found, switched to root as last resort" >&2
            fi         
        else
            error+=("${fn} is not a file, directory or function.")
            printf "$wrapErr" "${error[*]}" 1>&2
            return 1
        fi
        if [ -n "${debug:-}" ]; then
            for val in ${debug[@]}
            do
                local valArr=${val:-}[@]
                if [ -n "${!valArr:-}" ]; then
                    echo "# $(declare -p $val 2>/dev/null | cut -d' ' -f 3-)" >&2
                fi
            done
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