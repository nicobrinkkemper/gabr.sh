#!/usr/bin/env bash
# GABR_ENV/env
# Alters the output and behavior of the script.
# Valid string:
#   - default (dev)   - prevent terminal crash on error
#   - debug           - same as default, but print detailed internal workings of gabr
#   - prod            - don't prevent terminal crash on error 

# GABR_ROOT/root
# Alters the directory which to look for functions as last resort
# Valid string:
#    - Valid path to directory. e.g. ./scripts, $PWD, ~/

# GABR_DEFAULT/default
# Alters the function that is generated and called as last resort
# By default, a  generated function called 'usage' will print a generated variable called 'usage'
#    - Any function name, e.g. help, usage, info

function gabr(){
    set -Euo pipefail
    local IFS=$'\n\t'
    trap 'exitcode=$?; if ! [[ $exitcode -eq 0  ]] && ! [[ $env = prod ]]; then echo "return $exitcode prevented" 1>&2; return 0; fi; return $exitcode' ERR SIGINT
    trap 'exitcode=${exitcode:-${?}}' RETURN
    FUNCNEST=50
    if ! [[ -v exitcode ]]; then
        local exitcode
    fi
    if ! [[ -v pwd ]]; then
        local pwd="${PWD}"
    fi
    if ! [[ -v default ]]; then
        local default=usage # The default function name to fall back to when no functions are found
        if [[ -v GABR_DEFAULT ]]; then
            default=$GABR_DEFAULT
        fi
    fi
    if ! [[ -v root ]]; then
        local root=$PWD
        if [[ -v GABR_ROOT ]]; then
            root=$GABR_ROOT
        fi
    fi
    if ! [[ -v args ]]; then
        local -a args=()
    fi
    if ! [[ -v stack ]]; then
        local stack=$(declare -F)
    fi
    if ! [[ -v funcstack ]]; then
        local -a funcstack=(${FUNCNAME[@]})
    fi
    if ! [[ -v debug ]]; then
        local -a debug=()
    fi
    if ! [[ -v fn ]]; then
        local fn
    fi
    if ! [[ -v wrapErr ]]; then
        local wrapErr=$'\033[0;91m'%s$'\033[0m\n' # printfn LightRed with newline -- e.g. printfn ${wrapErr} "Error"
    fi
    if ! [[ -v _error ]]; then
        local -a _error=()
    fi
    if ! [[ -v dir ]]; then
        local dir=.
    fi
    if ! [[ -v $default ]]; then
        local $default="${FUNCNAME} <dir | filename | function> <arguments> - e.g. ${FUNCNAME} usage"
    fi
    if ! [[ -v primaryFn ]]; then
        local primaryFn=${1:-}
    fi
    if ! [[ -v files ]]; then
        local -A files=()
    fi
    if ! [[ -v env ]]; then
        local env=dev
        if [[ -v GABR_ENV ]]; then
            env=$GABR_ENV
        fi
    fi
    if ! [[ -v $default ]]; then
        local $default="${FUNCNAME} <dir | filename | function> <arguments> - e.g. ${FUNCNAME} usage"
    fi
    (
    eval "\
$default(){
    echo \"\${!default}\" >&2
}";
    if [ $# -eq 0 ]; then
        usage
        return;
    fi
    function _filename() ( # -- get the filename from a path
        local path="${1:-}"
        local juggle=${path##*/}
        echo ${juggle%%.*}
    )
    local prevFn=''
    while [[ $# -ne 0 ]];
    do
        if [[ -v fn ]]; then
            prevFn=$fn
        fi
        fn=${1:-$default}; shift; args=(${@});
        if [[ -v debug ]]; then
            echo "#___$(_filename ${fn^^})___" >&2
            if [[ ${#args[@]} -ne 0 ]]; then
                echo "# $(IFS=$'-'; echo ${args[@]}) " >&2
            fi
        fi
        if [[ ${fn::2} = '-' ]]; then
            break
        elif [[ ${fn::2} = '--' ]]; then
            if [[ ${fn^^} = '--FILE' ]] || [[ ${fn^^} = '--DERIVE' ]]; then
                if ! [[ -v args  ]]; then
                    _error+=("Can not find a file without args")
                    echo ${_error[*]} 1>&2
                    return 1;
                elif  ! [[ -r ${args} ]]; then
                    _error+=("File not found: ${args}")
                    echo ${_error[*]} 1>&2
                    return 1;
                elif [[ -v files[$args] ]]; then
                    _error+=("File already imported: ${args}")
                    echo ${_error[*]} 1>&2
                    return 1
                else
                    if [[ -v debug ]]; then
                        echo "# SOURCING $(_filename ${args^^})---" >&2
                    fi
                    prevFn=$fn
                    fn=$1; shift; args=(${@});
                    files+=([$fn]=$fn)
                    source $fn
                    if [[ $(type -t $(_filename $fn)) = function ]]; then
                        if [[ ${prevFn^^} = '--DERIVE' ]] || ! [[ -v args ]] || [[ ${args::1} = '-' ]]; then
                            if [[ -v debug ]]; then
                                echo "# DERIVED ${fn^^}" >&2
                            fi
                            set -- $(_filename $fn) ${args[@]}
                        fi
                    elif [[ -v debug ]]; then
                        echo "# READ $(_filename ${args^^})---" >&2
                    fi
                fi
            fi
        elif [[ $(type -t ${fn:-}) = function ]]; then
            if [[ -v debug ]]; then
                echo "---FOUND-${fn^^}---" >&2
            fi
            cd $dir
            dir=.
            $fn ${args[@]}
            exitcode=$?
            return $?
        elif [[ -f $fn ]]; then # allow file
            set -- --file $fn ${args[@]}
            if [[ -v debug ]]; then
                echo "$fn is a full path to a file" >&2
            fi                                
        elif [[ -f ${dir}/$fn ]]; then # allow files in dir
            set -- --file ${dir}/$fn ${args[@]}
            if [[ -v debug ]]; then
                echo "$fn is a file in $dir" >&2
            fi          
        elif [[ -f ${dir}/$fn.sh ]]; then # allow files omitting .sh
            set -- --derive ${dir}/$fn.sh ${args[@]}
            if [[ -v debug ]]; then
                echo "$fn is a file in $dir and perhaps a function" >&2
            fi           
        elif [[ -f  ${dir}/${fn}/$fn.sh ]]; then # allow dir same as file
            set -- --derive ${dir}/${fn}/$fn.sh ${args[@]}
            dir+=/$fn
            if [[ -v debug ]]; then
                echo "$fn is a directory and a file in $dir" >&2
            fi          
        elif [[ -d $fn ]]; then # allow directory
            dir+=/$fn 
            if [[ -v debug ]]; then
                echo "$fn is a directory" >&2
            fi
        elif ! [[ $dir = . ]]; then # allow the same as above, but in current directory
            dir=.
            set -- $fn ${args[@]}
            if [[ -v debug ]]; then
                echo "Nothing found, retrying in PWD" >&2
            fi
        elif ! [[ $PWD = $root ]]; then # allow the same as above, but in root directory
            cd $root
            set -- $fn ${args[@]}   
            if [[ -v debug ]]; then
                echo "Nothing found, switched to root as last resort" >&2
            fi                  
        else
            _error+=("${fn} is not a valid option.")
            echo ${_error[*]} 1>&2
            return 1
        fi
    done
    )
    return;
}

if [[ "$0" = "$BASH_SOURCE" ]]; then
    declare IFS=$'\n\t'
    gabr ${*}
fi