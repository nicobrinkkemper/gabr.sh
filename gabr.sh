#!/usr/bin/env bash

declare -x ENV=${ENV:-dev}
declare -x GABR_ROOT=${GABR_ROOT:-"$(command git rev-parse --show-toplevel)"} # Making this global allows us to access anywhere.

function gabr() { # Run a variety of bash functions inside this git repo
    FUNCNEST=100
    # Development mode
    if [ ${#FUNCNAME[@]} -eq 1 ] && [[ ${ENV} = dev  ]]; then
        bash $(! [[ $PWD = $GABR_ROOT ]] && echo  ${GABR_ROOT}/)${BASH_SOURCE} ${*}
        # sidenote: running as file will do hot-reloading (no resourcing needed) and prevent terminal exit upon error
        return
    fi
    # Set up error trapping early
    # You never know.
    function _reportLines() ( # <lineno> <file> <area (default:3)> -- prints a line with surrounding lines
        awk 'NR>L-'${3:-3}' && NR<L+'${3:-3}' { printf "%-5d%'$(( ${3:-3} - 1 ))'s%s\n",NR,(NR==L?">>>":""),$0 }' L=${1:-} ${2:-}
    )

    function _reportError() ( # -- Prints code that is cause of error -- e.g. trap '_reportError' ERR
        local IFS=$' '
        set -- $(caller)
        echo "Stopped at line ${1} - ${2}" 1>&2
        if [[ $ENV = dev ]]; then
            _reportLines ${1} ${2} 3 1>&2
            return
        fi
        return 1  # bash wil exit
    )
    trap '_reportError' ERR

    # Strictmode - stop at slightest hick-up
    set -euo pipefail
    # All locals used in this program
    local IFS pwd fn prevFn primaryFn dir usage example wrapErr reuseFn debug
    local -A files=() # files state
    local -a args=() debug=() # arguments state, debug state
    # Initial program state
    IFS=$'\n\t' # Must be before array assign
    args=(${*})
    wrapErr=$'\033[0;91m'%s$'\033[0m\n' # printfn LightRed with newline -- e.g. printfn ${wrapErr} "Error"
    dir=.
    pwd=${PWD}
    usage="<dir> | <file> | <function> | <arguments>"
    example="gabr help"
    usagePrefix="Usage: gabr"
    primaryFn=${1:-}

    files=([${BASH_SOURCE}]=${BASH_SOURCE})
    fn=${BASH_SOURCE} # won't be executed, will become prevFn _onScope
    if ! [[ $pwd = $GABR_ROOT ]]; then
        args=(root ${args[@]}) # _onScope should start by cd'ing to root directory
    else
        pwd=.
    fi
    trap '_onRun; _onCleanUp;' RETURN

    # Now for our private functions
    function _onCleanUp() { # Cleans up all functions added to global scope and return back to PWD
        trap - ERR
        trap - RETURN
        trap - DEBUG
        set +euo pipefail # don't keep the bash strict
        unset _onScope _onRun _shiftArgs _onCleanUp _onDefault _reportFnCallable _reportError _debugState filename
        if ! [[ "$pwd" = "$PWD" ]]; then
            cd $pwd;
        fi
    }

    function _onRun() ( # <fn> <args> -- Run fn with args in subshell at dir, report when uncallable in scope
        trap '_reportError' ERR
        
        gabr(){ # A simple gabr implementation for subshell
            if [[ -n ${1:-} ]]; then
                args=(${@})
            fi
            _onRun
        }
        _onScope
        
        if ! [[ $(type -t "$fn") = "function" ]]; then
            _reportFnCallable
            return
        fi

        # we are done with setting up scope
        if [[ -v debug ]]; then
            echo "Running: $fn ${args[@]}" >&2
            _debugState dir
        fi
        cd $dir;
        $fn ${args[@]}
    )

    function _onDefault() { # Sets fn and args to run usage
        fn=usage
        args=()
    }
    # these are all possible functions
    function _onScope() { # Adds functions to the scope based on your arguments. Sets correct fn and args to run based on input.
        trap '_reportError' ERR
        _shiftArgs
        if [[ -v debug ]]; then
            echo "Scoping: $fn ${args[@]}" >&2
            _debugState;
        fi
        if [[ $(type -t "$fn") = "function" ]]; then
            return
        fi
        case $fn in # start fn switch statement
        usage)
            usage(){ # <usage> -- Displays usage when no arguments given
                echo "${usagePrefix} ${primaryFn} ${usage[*]} -- e.g. ${example}"
            }
            ;;
        debug-*)
            debug+=(${fn##*debug\-})
            _onScope
            ;;
        debug)
            debug=(fn args)
            _onScope
            ;;
        root)
            fn=$prevFn # act like root was never called, fn will become prevFn in next scope
            pwd=${dir}
            cd $GABR_ROOT;
            dir=.
            _onScope
            ;;
        file)
            if ! [[ -v args  ]]; then
                usage="<filename> <function> <arguments>"
                example="gabr file ./git.sh help"
            elif  ! [[ -r ${args} ]]; then
                printf "${wrapErr}" "File not found: ${args}" 1>&2
                return;
            elif [[ -v files[$args] ]]; then
                _shiftArgs
                printf "${wrapErr}" "File already imported: ${fn}" 1>&2
                _shiftArgs
            else
                if [[ "$(filename $args)" = $prevFn ]]; then # fn from filename initiated by previous argument
                    reuseFn=$prevFn
                fi
                _shiftArgs
                source $fn
                files+=([${fn}]=$fn)
                if [[ -v reuseFn ]] && [[ $(type -t "$reuseFn") = "function" ]]; then # only reuse the previous argument if the function is there
                    args=($reuseFn ${args[@]}) # 'gabr ./help.sh help' can be reduced to just 'gabr help'
                    # sidenote: The reduncancy thing only works when your argument is also a callable function.
                    #           'gabr ./help.sh' will just source the file inside a subshell.
                    #            Only when you write 'gabr help' will the file be imported AND the function called 
                fi
            fi
            if ! [[ -v args ]]; then # fn from filename initiated by absent arguments
                args=($(filename ${fn}))
            elif [[ ${args::2} = '--' ]]; then # fn from filename initiated by a flag
                args=($(filename ${fn}) ${args[@]})
            elif [[ ${args} = '-' ]]; then # fn from filename initiated by a single dash
                set -- ${args[@]}
                shift # omit the dash
                args=($(filename ${fn}) ${@})
            fi
            _onScope
            ;;
        *)
            if [[ -f $fn ]]; then                               # allow file
                args=(file $fn ${args[@]})                      
            elif [[ -f ${dir}/$fn ]]; then                      # allow files in dir
                args=(file ${dir}/$fn ${args[@]})               
            elif [[ -f ${dir}/$fn.sh ]]; then                   # allow files omitting .sh
                args=(file ${dir}/$fn.sh ${args[@]})            
            elif [[ -f ${dir}/$prevFn.sh ]]; then               # also allow files with the same name as directory
                args=(file ${dir}/${prevFn}.sh $fn ${args[@]})  
            elif [[ -d $fn ]]; then                             # allow directory
                dir+=/$fn   
            elif ! [[ $dir = . ]]; then                         # allow the same as above, but in current directory
                dir=.
                args=($fn ${args[@]})
            elif ! [[ $PWD != $GABR_ROOT ]]; then               # allow the same as above, but in root directory
                args=(root $fn ${args[@]})                     
            else
                printf "${wrapErr}" "${fn} is not a valid option" 1>&2
                return
            fi
            _onScope
            ;;
        esac

        return # end of _onScope
    }
    
    function _shiftArgs() { #--  Shifts args and sets fn to shifted value
        if [[ ${#args[@]} -eq 0 ]]; then
            _onDefault
            return
        elif [[ ${args::2} = '--' ]]; then
            printf "${wrapErr}" "Flags should not be processed by gabr (found ${args})." 1>&2
            return 1
        elif [[ -v fn ]]; then
            prevFn=$fn
        fi
        set -- ${args[*]}
        fn=$1
        shift
        args=(${@})
    }

    # Protected helper function
    filename() ( # <path (default:$BASH_SOURCE)> -- get the filename from a path
        local path="${1:-${BASH_SOURCE}}"
        local juggle=${path##*/}
        echo ${juggle%%.*}
    )

    function _reportFnCallable() ( # [ fn ] -- prints message that $fn is not callable
        printf "${wrapErr}" "Did not find function \"${fn}\" in ${FUNCNAME[2]} <-- ${FUNCNAME[1]}" 1>&2
        
        local options="$(local stripped=$(filename $fn); declare -F | awk '!/^declare -f _/{ print $3 }' | awk '/'${stripped::3}'/{print "  "$0}')"  || true
        if ! [[ ${#options} -eq 0 ]]; then
            printf "${wrapErr}" "Did you mean:
${options[@]}" 1>&2
        fi
        return
    )

    function _debugState() ( # -- [debug] -- prints the debug message -- e.g. gabr git help
        local IFS=$' '
        set -- ${@} ${debug[@]}
        local str juggleDeclare primary
        while [[ -n ${1:-} ]]; do
            primary=${1:-}
            if ! [[ -v $primary ]]; then
                juggleDeclare=$(echo $(declare -p $primary 2>/dev/null))
                if [[ -z ${juggleDeclare} ]]; then # test if var is usable by declare -p
                    echo "$primary is not a variable" >&2
                    return 0
                fi
            fi
            str="$(declare -p ${primary})"
            juggleDeclare=${str##*declare\ -}
            echo ${juggleDeclare[@]:2} >&2
            shift
        done
    )
}

# Run the function when the file is ran
if [[ "$0" = "$BASH_SOURCE" ]]; then
    declare IFS=$'\n\t'
    gabr ${*}
fi

# That's it folks
