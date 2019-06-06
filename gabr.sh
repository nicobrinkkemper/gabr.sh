#!/usr/bin/env bash
# *GABR_ENV* alters the output and behavior of the script
# - default (dev)   - prevent terminal crash on error
# - prod            - don't prevent terminal crash on error 
# - debug           - print detailed internal workings of gabr
# declare -x GABR_ENV=dev # dev
# -
# *GABR_ROOT* alters the directory which to look for functions as last resort
# Gabr falls back to source location when below line is uncommented
# -
# export GABR_ROOT=${GABR_ROOT:-$PWD}
# -
# GABR_DEFAULT alters the function that is generated and called as last resort
# A function called 'usage' will print a variable called 'usage'
# declare -x GABR_DEFAULT=usage

# GABR_NO_AUTO_UPGRADE
# Set to any value to opt-out of functionality to upgrade a functions contents with traps
# declare -x GABR_NO_AUTO_UPGRADE=true

declare -x GABR_NO_AUTO_UPGRADE=${GABR_NO_AUTO_UPGRADE:-}

# declare -x GABR_DEFAULT=${GABR_DEFAULT:-"usage"} 
trap - ERR SIGINT
trap - RETURN
trap '' ERR SIGINT
trap '' RETURN
function gabr() { # Run a variety of bash functions inside this git repo
FUNCNEST=50
# Strictmode - stop at slightest hick-up
set -euo pipefail
# Following variables will never be inherited
local prevFn reuseFn
local IFS=$'\n\t'
if ! [[ -v oldIFS ]]; then
    local oldIFS=$IFS
fi
if ! [[ -v pwd ]]; then
    local pwd="${PWD}"
fi
if ! [[ -v stack ]]; then
    local stack=$(declare -F)
fi
if ! [[ -v funcstack ]]; then
    local -a funcstack=(${FUNCNAME[@]})
fi
# 'local' variables wrapped with 'if ! [[ -v' like below has a few benefits here:
# Because of 'local' the global namespace is never polluted with variable declarations
# Because of 'if ! [[ -v', existing variables won't be recreated, but inherited
if ! [[ -v default ]]; then
    local default=usage # The default function name to fall back to when no functions are found
    if [[ -v GABR_DEFAULT ]]; then
        default=$GABR_DEFAULT
    fi
fi
if ! [[ -v debug ]]; then
    local debug=()
    if [[ -v GABR_ENV ]] && [[ $GABR_ENV = debug ]]; then
        debug=(args)
    fi
fi
if ! [[ -v env ]]; then
    local env=dev
    if [[ -v GABR_ENV ]]; then
        env=$GABR_ENV
    fi
fi
if ! [[ -v root ]]; then
    local root=$PWD
    if [[ -v GABR_ROOT ]]; then
        root=$GABR_ROOT
    fi
fi
if ! [[ -v args ]] || ! [[ $# -eq 0 ]]; then
    local -a args=(${*})
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
    local -A files=([${BASH_SOURCE}]=${BASH_SOURCE})
fi
if ! [[ -v fn ]]; then
    local fn=${BASH_SOURCE} # won't be executed, will become prevFn _onScope
fi
if ! [[ -v exitcode ]]; then
    local exitcode=$?
fi
# functions wrapped with 'if ! type -t ' will be inherited just like variables wrapped in 'if ! [[ -v '
# actually the effect is the same without the if statements, because when you overwrite a function
# it will still inherit the position of the first created function. However it *can* lead to nuanced
# differences
if ! [[ $(type -t _fnContents) = function  ]]; then
function _fnContents() { # Returns the body of variable fn (or position 1) as a string which can be evaled
    local fn=${1}
    local raw="$(declare -f ${fn:-${1:-}})"
    if [[ ${raw[@]: -1} = '}' ]]; then
        local rmLeft=${raw#*\{} # remove left of curly opening
        local rmRight=${rmLeft%\}*} # remove right of curly opening
    else
        _error+=("Function $fn does not end with curly bracket }. This should be default bash behavior")
        return 1
    fi
    if [[ -z ${rmRight} ]]; then
        _error+=("Function $fn does not have any content")
        return 1
    fi
    printf "%s" "${rmRight}" # print and close with ;
}
fi
if ! [[ $(type -t _filename) = function  ]]; then
function _filename() ( # <path (default:$BASH_SOURCE)> -- get the _filename from a path
    local path="${1:-${BASH_SOURCE}}"
    local juggle=${path##*/}
    echo ${juggle%%.*}
)
fi
if ! [[ $(type -t _onCleanUp) = function  ]]; then
function _onCleanUp() { # Cleans up all functions added to global scope and return back to PWD
    set +euo pipefail
    declare -x IFS=$oldIFS
    if ! [[ -v stack ]] || ! [[ -v pwd ]]; then
        return
    fi
    trap - ERR SIGINT
    trap - RETURN
    trap '' ERR SIGINT
    trap '' RETURN
    local -a diff=($(echo "${stack}" "${stack}" "$(declare -F)" | tr ' ' '\n' | sort | uniq -u))
    if [[ -v diff ]]; then
        if [[ -v debug ]]; then
            echo "Cleaned up ${diff[@]}" >&2
        fi
        unset -f ${diff[@]}
    elif [[ -v debug ]]; then
        echo "No difference in stack" >&2
    fi
    if ! [[ "$pwd" = "$(pwd)" ]]; then
        cd $pwd;
        if [[ -v debug ]]; then
            echo "Switched back to $(pwd) and cleaned-up scope" >&2
        fi
    elif [[ -v debug ]]; then
        echo "Didn't cd anywhere" >&2
    fi
    if [[ -v debug ]]; then
        echo "exitcode=${exitcode:-'0 (default)')}" >&2
        echo "FUNCNAME=${FUNCNAME[@]}" >&2
        echo "caller=$(caller 0)" >&2
    fi
    if [[ -v _error ]] && [[ -n $_error ]]; then
        printf "${wrapErr}" "A error occured" 1>&2
        printf "${wrapErr}" $_error 1>&2
        if [[ $exitcode -eq 0 ]]; then
            printf "$wrapErr" "exitcode set to 1 due to errors" >&2
            exitcode=1
        fi
    fi
    if ! [[ $env = prod ]] && [[ $exitcode -ne 0 ]]; then
        printf "$wrapErr" "Exitcode $exitcode prevented, returned 0 instead" >&2
        return 0
    else
        if [[ -v debug ]]; then
            echo "Returning with $exitcode" >&2
        fi
        exitcode=$exitcode
        return $exitcode
    fi
}
fi
if ! [[ $(type -t _preventExit) = function  ]]; then
function _preventExit(){
    if [[ ${exitcode:-$?} -ne 0 ]] && ! [[ $env = prod ]]; then
        return 0
    fi
}
fi
if ! [[ $(type -t _shiftArgs) = function  ]]; then
function _shiftArgs() { # Shifts args and sets fn to shifted value -- e.g. _shiftArgs
    if [[ ${#args[@]} -eq 0 ]]; then
        fn=${default}
        args=()
        return
    elif [[ ${args::2} = '--' ]]; then
        _error+=("Flags should not be processed by gabr (found ${args}).")
        return 1
    elif [[ -v fn ]]; then
        prevFn=$fn
    fi
    set -- ${args[*]}
    fn=$1
    shift
    args=(${@})
}
fi
if ! [[ $(type -t _onScope) = function  ]]; then
function _onScope() { # Adds functions to the scope based on your arguments. -- 
    set -o pipefail
    trap 'exitcode=$?; return $exitcode' ERR SIGINT
    _shiftArgs
    if [[ -v exitcode ]] && [[ $exitcode -ne 0 ]]; then
        return $exitcode
    fi
    if [[ -v debug ]]; then
        echo "Scoping: $fn ${args[@]}" >&2
        _debugState;
    fi
    if [[ $(type -t "$fn") = "function" ]]; then
        if [[ -v debug ]]; then
            echo "Found function $fn in $PWD $dir" >&2
            echo "$(declare -f $fn)" >&2
        fi 
        return
    fi
    case $fn in # start fn switch statement
    ${default})
        eval "\
$default(){
echo \"${!default}\";
return
}"
        ;;
    debug-*)
        debug+=(${fn##*debug\-})
        _onScope
        ;;
    debug)
        debug=(fn args)
        _onScope
        ;;
    file)
        if ! [[ -v args  ]]; then
            _error+=("Can not find a file without args")
            return 1;
        elif  ! [[ -r ${args} ]]; then
            _error+=("File not found: ${args}")
            return 1;
        elif [[ -v files[$args] ]]; then
            if ! [[ "$(_filename $args)" = "${prevFn:-}" ]]; then
                _error+=("File already imported: ${args}")
                return 1
            elif [[ -v debug ]]; then
                echo "No function called $prevFn found in $args" >&2
            fi
            _shiftArgs
            _shiftArgs
            return 1;
        else
            if [[ "$(_filename $args)" = $prevFn ]]; then # fn from _filename initiated by previous argument
                reuseFn=$prevFn
            fi
            _shiftArgs
            if [[ -v debug ]]; then
                echo "---START-IMPORT-${fn^^}" >&2
                echo "If you crash here, the file errored out." >&2
            fi
            source $fn # if you crash here, the file errored out!
            if [[ -v debug ]]; then
                echo "---DONE-IMPORT-${fn^^}" >&2
            fi
            files+=([${fn}]=$fn)
            if [[ -v reuseFn ]] && [[ $(type -t "$reuseFn") = "function" ]]; then # only reuse the previous argument if the function is there
                args=($reuseFn ${args[@]}) # 'gabr ./help.sh help' can be reduced to just 'gabr help'
                if [[ -v debug ]]; then
                    echo "Argument $reuseFn will be reused as a function" >&2
                fi
                # sidenote: The reduncancy thing only works when your argument is also a callable function.
                #           'gabr ./help.sh' will just source the file inside a subshell.
                #            Only when you write 'gabr help' will the file be imported AND the function called 
            fi
        fi
        if ! [[ -v args ]]; then # fn from _filename initiated by absent arguments
            args=($(_filename ${fn}))
            if [[ -v debug ]]; then
                echo "Argument processing is stopped by absent arguments" >&2
                echo "Argument $fn is converted to $(_filename ${fn}) as last resort" >&2
            fi
        elif [[ ${args::2} = '--' ]]; then # fn from _filename initiated by a flag
            args=($(_filename ${fn}) ${args[@]})
            if [[ -v debug ]]; then
                echo "Argument processing is stopped by ${args}" >&2
                echo "$fn is converted to $(_filename ${fn}) as last resort" >&2
            fi
        elif [[ ${args} = '-' ]]; then # fn from _filename initiated by a single dash
            set -- ${args[@]}
            shift # omit the dash
            args=($(_filename ${fn}) ${@})
            if [[ -v debug ]]; then
                echo "Argument processing is stopped by -" >&2
                echo "$fn is converted to $(_filename ${fn}) as last resort" >&2
            fi
        fi
        _onScope 
        ;;
    *)
        if [[ -v debug ]]; then
            echo "Looking for file or directory $fn in $PWD $dir" >&2
        fi 
        if [[ -f $fn ]]; then # allow file
            args=(file $fn ${args[@]})
            if [[ -v debug ]]; then
                echo "$fn is a full path to a file" >&2
            fi                                
        elif [[ -f ${dir}/$fn ]]; then # allow files in dir
            args=(file ${dir}/$fn ${args[@]})
            if [[ -v debug ]]; then
                echo "$fn is a file in $dir" >&2
            fi          
        elif [[ -f ${dir}/$fn.sh ]]; then # allow files omitting .sh
            args=(file ${dir}/$fn.sh ${args[@]})
            if [[ -v debug ]]; then
                echo "$fn is a file in $dir and perhaps a function" >&2
            fi           
        elif [[ -f  ${dir}/${fn}/$fn.sh ]]; then # allow dir same as file
            args=(file ${dir}/${fn}/$fn.sh ${args[@]})  
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
            args=($fn ${args[@]})
            if [[ -v debug ]]; then
                echo "Nothing found, retrying in PWD" >&2
            fi
        elif ! [[ $PWD = $root ]]; then # allow the same as above, but in root directory
            cd $root
            args=($fn ${args[@]})   
            if [[ -v debug ]]; then
                echo "Nothing found, switched to root as last resort" >&2
                _debugState PWD dir
            fi                  
        else
            _error+=("${fn} is not a valid option. $(_listFnAlternatives)")
            return 1
        fi
        _onScope
        ;;
    esac
    return # end of _onScope
}
fi
if ! [[ $(type -t _listFnAlternatives) = function  ]]; then
function _listFnAlternatives() (
    local stripped=$(_filename $fn);
    local chunk=${stripped::4}
    local -a possible=($(IFS=' ' echo "${stack}" "${stack}" "$(declare -F)" | tr ' ' '\n' | sort | uniq -u))
    local -a public=($(echo "${possible[*]}" | awk '!/^_/{ print "  "$0 }'))
    local -a similar=($(echo "${public[*]}" | awk '/'${chunk}'/{ print "    "$0 }'))
    if ! [[ ${#similar[@]} -eq 0 ]]; then
        echo "\
Did you mean:
${similar[*]}"
    elif ! [[ ${#public[@]} -eq 0 ]]; then
        echo "\
Here is a list of options:
${public[*]}"
    else    
        echo "\
Try these files:
$(find ./ -maxdepth 1 -name '*.sh')"
    fi
)
fi
if ! [[ $(type -t _debugState) = function  ]]; then
function _debugState() ( # -- <debug> -- prints the debug message -- e.g. gabr git help
    local IFS=$' '
    set -- ${@} ${debug[@]}
    local str juggleDeclare primary
    while [[ -n ${1:-} ]]; do
        primary=${1:-}
        if ! [[ -v $primary ]] && [[ -z $(echo $(declare -p $primary 2>/dev/null)) ]]; then # test if var is usable by declare -p
            echo "$primary is not a variable" >&2
            return
        fi
        str="$(declare -p ${primary})"
        juggleDeclare=${str##*declare\ -}
        echo ${juggleDeclare[@]:2} >&2
        shift
    done
)
fi
# Done with setting up functions
if ! [[ -v onCleanUp ]]; then
    # store this code as it might be gone at some point
    local onCleanUp="\$(_fnContents _onCleanUp)"
    # go ahead and try as function, for me it errors:
    # *** longjmp causes uninitialized stack frame ***: -bash terminated
fi

# Run time
set -o errtrace
trap 'exitcode=$?; return $exitcode' ERR SIGINT
if eval '_onScope'; then
# we are done with setting up scope
if [[ $(type -t $fn) = function ]]; then
    
    if [[ -v debug ]]; then
        echo "Running:" >&2
        _debugState fn args
    fi
    if ! [[ ${dir} = '.' ]]; then
        cd $dir;
        dir=.
        if [[ -v debug ]]; then
            echo "Switched:" >&2
            _debugState dir PWD pwd
        fi
    fi
    if ! [[ -v GABR_NO_AUTO_UPGRADE ]] || [[ -z ${GABR_NO_AUTO_UPGRADE:-} ]]; then
        # This is a try-catch solution
        # Following eval handles errors inside a function, like typo's, ctrl+c, etc
        eval "\
$fn(){
    set -o pipefail
    trap 'exitcode=\$?;' RETURN
    trap 'exitcode=\$?; return \$exitcode' ERR SIGINT
    $(_fnContents $fn)
}
"
        if [[ -v debug ]]; then
            echo "Upgraded function $fn" >&2
            echo "$(declare -f $fn)" >&2
        fi
    elif [[ -v debug ]]; then
        echo "Skipped upgrading function $fn" >&2
    fi
    if [[ -v debug ]]; then
        echo "---START-${fn^^}---" >&2
        local runningFn=$fn
    fi
    # $fn ${args[@]}
    set -o errtrace
    trap 'exitcode=$?; return $exitcode' ERR SIGINT
    if eval '$fn ${args[@]}'; then # this is really the meat of the program
        if [[ -v debug ]]; then
            echo "---DONE-${runningFn^^}---" >&2
        fi
    else
        exitcode=$?
        if [[ -v debug ]]; then
            echo "---FAILED-${runningFn^^}---" >&2
        fi
    fi
elif [[ -v FUNCNAME[1] ]]; then
    _error+=("Did not find function \"${fn}\" in ${FUNCNAME} <- ${FUNCNAME[1]}")
    return 1
else
    _error+=("Did not find function \"${fn}\" in ${FUNCNAME}")
    return 1
fi
fi # end onscope
# Folowing if statement tests for initial scope of gabr function
if [[ "${funcstack[@]}" = "${FUNCNAME[@]}" ]]; then
    _onCleanUp
else
    if [[ -v debug ]]; then
        echo "Will not prevent return code ${exitcode:-1}" >&2
        _debugState FUNCNAME
    fi
    return ${exitcode:-1}
fi
return # end of gabr function
}

# Run the function when the file is ran
if [[ "$0" = "$BASH_SOURCE" ]]; then
    declare IFS=$'\n\t'
    gabr ${*}
fi

# That's it folks
