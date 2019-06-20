#!/usr/bin/env bash
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ]; then
local -A versions=(
    ["3.2"]="3.2"
    ["4.0"]="4.0"
    ["4.1"]="4.1"
    ["4.2"]="4.2"
    ["4.3"]="4.3"
    ["4.4"]="4.4"
)
function _isVersion(){
    [[ -v versions["${1:-}"] ]] && [[ ${versions[${1}]} = ${1} ]]
}
declare -a bashvers=()
declare rootVolume=$(pwd)

# Strip all version numbers from arguments and assign to array
if _isVersion ${1:-}; then
    while _isVersion ${1:-}
    do
        echo "Added version ${1}" >&2
        bashvers+=(${versions["${1}"]})
        shift
    done
fi

# Implement usage.md
if [[ $# -eq 0 ]]; then
    set  -- usage
    local usageFiles=" [$( echo ${!versions[@]} | tr ' ' '|')]"
# else
fi
    declare dir=$(git rev-parse --show-toplevel) # functions target root directory

# Run all versions when non givens
if ! [[ -v bashvers ]]; then
    echo "# Running for all versions" >&2
    bashvers=(${!versions[@]})
fi

# Check for WSL
case "$(cat /proc/version)" in
    *Microsoft*)
        echo "# Asumed Windows Subsystem for Linux" >&2
        rootVolume=$(wslpath -w ${rootVolume})
        ;;
esac

function build()( # -- e.g. docker 3.2 build
    if [ $# -ne 0 ]; then  bashvers=${@}; fi
    for bashver in ${bashvers[@]} 
    do
        docker build --build-arg bashver=${bashver} --tag bats/bats:bash-${bashver} .
    done
)

function test()( # -- e.g. docker 3.2 test
    if [ $# -ne 0 ]; then  bashvers=${@}; fi
    for bashver in ${bashvers[@]} 
    do
        docker run bash:${bashver} --version
        time docker run\
            -v ${rootVolume}:/opt/gabr/\
            bats/bats:bash-${bashver} --tap /opt/gabr/test
    done
)

function buildtest(){ # -- e.g. docker 3.2 buildtest
    build $@;
    test $@;
}
else
    echo "To use ${BASH_SOURCE}, please update Bash to 4.3+" 1>&2
    (exit 1)
fi