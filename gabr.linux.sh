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
    if ! [[ -v GABR_STRICT_MODE ]]; then
        local GABR_STRICT_MODE=on
    fi
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
    if ! [[ -v default ]]; then
        local default=${GABR_DEFAULT:-usage} # By default a function called 'usage' prints a variable called 'usage' through variable indirection
    fi
    if ! [[ -v root ]]; then
        local root=${GABR_ROOT:-${PWD}}
    fi
    # usage
    if ! [[ -v usage ]]; then
        local usage="\
${FUNCNAME} [directory | file] function [arguments] -- A function to call other functions.
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
    if [ "${GABR_STRICT_MODE}" = 'on' ]; then
        set -eEuo pipefail
        local IFS=$'\n\t'
        trap 'return $?' ERR SIGINT
        GABR_STRICT_MODE="already-on"
    fi
    # helpers
    _isFn(){    [[ $(type -t ${fn}) = function ]]; }
    _isDebug(){ [[ -v GABR_DEBUG_MODE ]]; }
    _isFile(){  [[ -f ${dir}/${fn} ]]; }
    _isFileExt(){  [[ -f ${dir}/${fn}${ext} ]]; }
    _isDir(){   [[ -d ${dir}/${fn} ]]; }
    _isDefault(){ [[ ${fn} = ${default} ]]; }
    _isRoot()( ! [[ ${dir:0:${#root}} = $root ]] )
    _setDefault(){
        if [[ ${fn} = usage ]]; then
            usage() {
                echo $usage >&2
            }
        else
            source /dev/stdin << EOF
$default() {
    echo '${!default}' >&2
}
EOF
        fi
    }
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
        if [ "${fn::1}" = '-' ]; then # disallow dash
            break
        elif _isFn; then # call a function
            shift
            args=(${@:-})
            cd $dir
            dir=.
            _isDebug && set -x
            ${fn} ${@:-};
            _isDebug && set +x
            break
        elif [ -n "${file:-}" ]; then # source a file
            file=$file
            if ! [ -r "${file:-}" ]; then
                printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "'$file' is not a readable file" 1>&2
                return 1
            fi
            shift
            args=(${@:-})
            _isDebug && set -x
            . $file # source the file
            _isDebug && set +x
            unset file
            set -- $fn ${@:-} # continue looking for a function
        elif _isFileExt; then # allow files with extension
            file=$dir/${fn}$ext
            continue
        elif _isFile; then # allow files without extension
            file=$dir/$fn
            continue
        elif _isDir; then # allow directory
            dir=$dir/$fn
            continue
        elif _isRoot; then # allow fallback directory (will only be true if dir does not start with root)
            dir=$root
            continue
        elif _isDefault; then  # allow generated default function
            _setDefault
        else
            printf $'\033[0;91m'"Warning: "%s$'\033[0m\n' "'$fn' could not be used as file, function or directory" 1>&2
            return 1
        fi
        if ! _isFn; then # If a function is sourced or generated (or has magically appeared), don't shift
            shift
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