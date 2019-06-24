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
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 4 ]
then
function gabr() {  # A function to run other functions 
    local FUNCNEST=50
    local default=${GABR_DEFAULT:-usage} 
    local fn file dir
    local -a args=()
    local -A files=()
    local -a prevArgs=($FUNCNAME)
    local ext=${GABR_EXT:-'.sh'}
    # usage
    if ! [[ -v usage ]]; then
        local usage="\
$FUNCNAME ${prevArgs[@]} [directory | file] function [arguments] -- A function to call other functions.
"
    fi
    # customize usage
    if ! [[ $default = usage ]]; then
        if ! [[ -v default ]] || ! [[ \'$default\' = ${default@Q} ]]; then
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "default may not contain special characters" 1>&2
            return 1
        fi
        if ! [[ -v $default ]]; then
            local $default="$usage"
        fi
    fi
    # arguments
( # @enter subshell
    if [[ -v GABR_ROOT ]]; then
        cd $GABR_ROOT
    fi
    if [[ ${GABR_STRICT_MODE:-true} = true ]]; then
        set -eEuo pipefail
        local IFS=$'\n\t'
        trap 'return $?' ERR SIGINT
        GABR_STRICT_MODE="on"
    fi
    ! [[ -v prevArgs ]] && local -a prevArgs=()
    # helpers
    _isFn(){    [[ $(type -t $fn) = function ]]; }
    _canSource(){ ! [[ -v files[$file] ]] || ! [[ ${files[$file]} = $file ]]; }
    _isDebug(){ [[ -v GABR_DEBUG_MODE ]]; }
    # begin processing arguments
    if [ $# -eq 0 ]; then
        set -- $default
    fi
    while ! [ $# -eq 0 ];
    do
        fn=${1}
        if [[ ${fn::1} = - ]]; then # disallow dash
            prevArgs+=($1)
            shift
            if ! [ $# -eq 0 ]; then
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
        elif [[ -f ./${fn}${ext} ]]; then # allow a file with extension
            file=${fn}${ext}
            if ! _canSource; then
                set -- '-' "'$file' is already sourced by argument $fn" 1>&2
                continue
            fi
            files+=([$file]=$file)
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
        elif [[ -f ./${fn} ]]; then # allow a file without extension
            prevArgs+=($1)
            shift
            args=(${@:-})
            exec ${fn} $@ # execute the file
            break
        elif [[ -d ./${fn} ]]; then # allow a directory
            cd ./$fn
            dir=./$fn
        elif [[ ${fn} = usage ]]; then # allow a generated usage function
            usage() {
                echo $usage >&2
            }
        elif [[ ${fn} = ${default} ]]; then # allow a generated default function
            source /dev/stdin << EOF
$default() {
    echo '${!default}' >&2
}
EOF
            _isFn && continue
            set -- '-' "Could not generate default function"
        elif [ $# -gt 1 ]; then # shift arguments
            prevArgs+=($1)
            shift
        elif [ $# -eq 1 ] && [[ -f ./${default}${ext} ]] && [[ ${dir:-.} = ./$fn ]]; then
            prevArgs+=($1)
            set -- ${default:-usage} ${prevArgs[@]}
        elif [ $# -eq 1 ] && ! [[ ${#files[@]} -eq 0 ]]; then
            set -- '-' "\
'$fn' could not be used to call a function in file(s): $(echo ${!files[@]})"
        elif [ $# -eq 1 ] && [[ -v dir ]]; then
            set -- '-' "'$fn' could not be used to call a function in directory $dir"
        else
            set -- '-'  "'$fn' could not be used as file, function or directory"
        fi
    done
    return;
) # @close subshell
}
else
    echo "To use ${BASH_SOURCE}, please update Bash to 4.3+" 1>&2
    (exit 1)
fi
if [[ $0 = $BASH_SOURCE ]]; then
    gabr ${*}
fi