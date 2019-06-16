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
    if ! [[ -v args ]]; then
        local -a args=()
    elif [[ $# -eq 0 ]]; then
        set -- ${args[@]:-}
    fi
    if ! [[ -v debug ]]; then
        local -a debug=()
    fi
    if ! [[ -v fn ]]; then
        local fn
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
    # Set prod mode
    if [[ $env = prod ]]; then
        set -euo pipefail # this will crash terminal on error
    fi
    # Set debug mode
    if [[ $env = debug ]] && ! [[ -v debug ]]; then
        debug=(fn args dir)
    fi
    #usage
    if [[ -v usage ]]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    if ! [[ $default = usage ]]; then
        default="$(echo "${default}" | tr -dc "[:alnum:]" | tr "[:upper:]" "[:lower:]")" # should be save for eval, unless you're a wizard
        if ! [[ -v $default ]]; then
            local $default=usage
        fi
    fi
( # @enter subshell
    local IFS=$'\n\t'
    if [[ $env = dev ]] || [[ $env = debug ]]; then
        set -Euo pipefail
    fi
    trap '(exit $?)' ERR SIGINT
    if ! [[ "$(type -t $default)" = function ]]; then
        eval "\
$default(){
    echo \"\${!default}\" >&2
}";
    fi
    if [[ $# -eq 0 ]]; then
        $default
        return;
    fi
    while ! [[ $(type -t ${1:-}) = function ]]
    do
        if [[ -v debug ]]; then
            echo "# -----------" >&2
        fi
        if [[ $# -eq 0 ]]; then
            local -f _default=${default} # this will fail when default is still not a function somehow
            set -- $_default
        fi
        fn=${1}
        shift
        args=(${@})
        if [[ ${fn::1} = '-' ]]; then
            break
        elif [[ -f ${dir}/$fn ]]; then # allow files in dir
            . ${dir}/$fn
        elif [[ -f ${dir}/${fn}.sh ]]; then # allow files omitting .sh
            . ${dir}/${fn}.sh
        elif [[ -d ${dir}/$fn ]]; then # allow directory
            dir+=/$fn
            set -- ${fn} ${args[@]:-}
        elif ! [[ ${dir:0:${#root}} = $root ]]; then # allow the same in root directory
            dir=$root
            set -- $fn ${args[@]:-}
        fi
        if [[ -v debug ]]; then
            for val in ${debug[@]}
            do
                local valArr=${val}[@]
                if [[ -v $val ]] || [[ -n ${!valArr+set} ]]; then
                    printf "# "%s'\n' "# $(declare -p $val 2>/dev/null | cut -d' ' -f 3-)" >&2
                fi
            done
        fi
        if [[ $(type -t ${fn:-}) = function ]]; then
            set -- $fn ${args[@]:-}
        fi
    done
    if [[ -v debug ]]; then
        printf "# "%s'\n' "Calling ${@}" >&2
    fi
    cd $dir
    dir=.
    ${@};
    return;
# @close subshell
)
}
fi
if [ "$0" = "$BASH_SOURCE" ]; then
    declare IFS=$'\n\t'
    gabr ${*}
fi