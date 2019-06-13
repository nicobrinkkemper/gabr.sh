#!/usr/bin/env bash
# @file gabr.linux.sh
# @brief This file contains the original gabr function before it got butchered in order to support older Bash versions.
#
# @description The main benefit is cleaner code. But the draw-back is Bash 4.3+ only. 4.3+ supports
# associative arrays (-A) and -v flags. The -A flag is used to check if files are not being resourced, which
# is a minor extra feature. 
#
# @example
#   $ debug=(files)
#   $ gabr example human smile
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
    if ! [[ -v funcname ]]; then
        local -a funcname=(${FUNCNAME[@]})
    fi
    if ! [[ -v filename ]]; then
        local filename
    fi
    if ! [[ -v pathJuggle ]]; then
        local pathJuggle
    fi
    if ! [[ -v exitcode ]]; then
        local exitcode
    fi
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
    if ! [[ -v primaryFn ]]; then
        local primaryFn=${1:-}
    fi
    if ! ((${#files[@]})); then
        local -A files=([$BASH_SOURCE]=$BASH_SOURCE)
    fi
    if ! [[ -v env ]]; then
        local env=dev
    fi
    if ! [[ -v pwd ]]; then
        local pwd="${PWD}"
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
    if [[ $env = debug ]] && ! [[ -v debug ]]; then
        debug=(fn args dir filename)
    fi
    if ! [[ -v default ]]; then
        local default=usage # By default a function called 'usage' prints a variable called 'usage' through variable expansion
    fi
    if ! [[ -v root ]]; then
        local root=$PWD
    fi
    if ! [[ -v $default ]]; then
        local $default="\
${FUNCNAME} [--file]] [--derive] [file] function [arguments] -- A function to call other functions
    --file       A full path to a file
    --derive     A filename without extension
    1..N         Performs various checks to derive flags and optimize the API.
                 Flags are optional and not needed in most cases."
    fi
    if ! [[ -v stack ]]; then
        local stack=$(declare -F)
    fi
    if ! [[ -v wrapInfo ]]; then
        local wrapInfo="# "%s'\n'
    fi
    if ! [[ -v wrapErr ]]; then
        local wrapErr=$'\033[0;91m'"Warning: "%s$'\033[0m\n' # printfn LightRed with newline -- e.g. printfn ${wrapErr} "something went wrong"
    fi
    if ! [[ -v error ]]; then
        local -a error=()
    fi
    if [[ $env = prod ]]; then
        set -euo pipefail # this will crash terminal on error
    fi
( # @enter subshell
    local IFS=$'\n\t'
    if [[ $env = dev ]] || [[ $env = debug ]]; then
        set -Euo pipefail
    fi
    trap 'exitcode=$?; cd $pwd; (exit $exitcode); return $exitcode' ERR SIGINT
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
    local prevFn=''
    while [[ $# -ne 0 ]];
    do
        if [[ -v fn ]]; then
            prevFn=$fn
        fi
        fn=${1:-$default}; shift; args=(${@});
        if [[ -v debug ]]; then
            echo "# -----------" >&2
        fi
        if [[ ${fn::2} = '-' ]]; then
            break
        elif [[ ${fn::2} = '--' ]]; then
            if [[ ${fn^^} = '--FILE' ]] || [[ ${fn^^} = '--DERIVE' ]]; then
                
                if ! [[ -v args  ]]; then
                    error+=("Can not find a file without arguments")
                    printf "$wrapErr" "${error[*]}" 1>&2
                    return 1;
                elif  ! [[ -r ${args} ]]; then
                    error+=("File not found: ${args}")
                    printf "$wrapErr" "${error[*]}" 1>&2
                    return 1;
                elif [[ -v files[$args] ]]; then
                    error+=("File already imported: ${args}")
                    printf "$wrapErr" "${error[*]}" 1>&2
                    return 1
                else
                    prevFn=$fn
                    fn=$1; shift; args=(${@});
                    pathJuggle=${fn##*/}
                    filename=${pathJuggle%%.*}
                    files+=([$fn]=$fn)
                    source $fn
                    if [[ $(type -t ${filename}) = function ]]; then
                        if [[ ${prevFn^^} = '--DERIVE' ]] || ! [[ -v args ]] || [[ ${args::1} = '-' ]]; then
                            if [[ -v debug ]]; then
                                printf $wrapInfo "${fn} is derived" >&2
                            fi
                            set -- ${filename} ${args[@]:-}
                        fi
                    fi
                fi
            fi
        elif [[ "$(type -t ${fn:-})" = function ]]; then
            if [[ -v debug ]]; then
                printf "$wrapInfo" "Calling ${fn}" >&2
            fi
            cd $dir
            dir=.
            $fn ${args[@]:-};
            cd $pwd
            return $?
        elif [[ -f $fn ]]; then # allow file
            set -- --file $fn ${args[@]:-}                             
        elif [[ -f ${dir}/$fn ]]; then # allow files in dir
            set -- --file ${dir}/$fn ${args[@]:-}
        elif [[ -f ${dir}/$fn.sh ]]; then # allow files omitting .sh
            set -- --derive ${dir}/$fn.sh ${args[@]:-}
        elif [[ -f  ${dir}/${fn}/$fn.sh ]]; then # allow dir same as file
            set -- --derive ${dir}/${fn}/$fn.sh ${args[@]:-}
            dir+=/$fn 
        elif [[ -d $fn ]]; then # allow directory
            dir+=/$fn
        elif ! [[ $dir = . ]]; then # allow the same as above, but in current directory
            dir=.
            set -- $fn ${args[@]:-}
        elif ! [[ $PWD = $root ]]; then # allow the same as above, but in root directory
            cd $root
            set -- $fn ${args[@]:-}   
            if [[ -v debug ]]; then
                printf $wrapInfo "Nothing found, switched to root as last resort" >&2
            fi         
        else
            error+=("${fn} is not a file, directory or function.")
            printf "$wrapErr" "${error[*]}" 1>&2
            return 1
        fi
        if [[ -v debug ]]; then
            for val in ${debug[@]}
            do
                local valArr=${val}[@]
                if [[ -v $val ]] || [[ -n ${!valArr+set} ]]; then
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