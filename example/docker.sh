#!/usr/bin/env bash
if [ ${BASH_VERSION:0:1} -ge 4 ] && [ ${BASH_VERSION:2:1} -ge 3 ]; then
declare -A versions=(
    ["3.2"]="3.2"
    ["4.0"]="4.0"
    ["4.1"]="4.1"
    ["4.2"]="4.2"
    ["4.3"]="4.3"
    ["4.4"]="4.4"
)
function _isVersion(){
    [ -v versions["${1:-}"] ] && [[ ${versions[${1}]} = ${1} ]]
}
declare _rootVolume=$(git rev-parse --show-toplevel)
declare -a bashvers=(${!versions[@]})
declare example="[$( echo ${!versions[@]} | tr ' ' '|')]
Example: gabr example buildtest 3.2
Note: Running without version argument will run all version (and takes a while)"


function _supportWsl(){ # -- Converts unix to windows path with `wslpath`
    case "$(cat /proc/version)" in
        *Microsoft*)
            echo "# Asumed Windows Subsystem for Linux" >&2
            _rootVolume=$(wslpath -w ${_rootVolume})
            ;;
    esac
}

function _supportedVersions(){ # -- Assigns version arguments to the 'bashvers' array
    if [ $# -eq 0 ]; then
        echo "# ${FUNCNAME[1]} versions: '$( echo ${bashvers[@]} | tr ' ' '|')'" >&2;
        return
    fi
    bashvers=()
    while [ $# -ne 0 ]
    do
        ! _isVersion ${1} && echo "# '${1:-}' is not a supported version" >&2 && return 1
        echo "# Added version ${1}" >&2
        bashvers+=(${versions["${1}"]})
        shift
    done
}

function build()( # build a docker image for a Bash version to test with bats -- e.g. build 3.2
    cd $_rootVolume
    _supportedVersions ${@}
    set -- ${bashvers[@]}
    for bashver in ${@}
    do
        printf '\n%s\n' "Building $bashver..."
        docker build --build-arg bashver=${bashver} --tag bats/bats:bash-${bashver} .
    done
)

function test()( # test a Bash version with a docker image build with build -- e.g. test 3.2
    _supportedVersions ${@}
    set -- ${bashvers[@]}
    _supportWsl
    for bashver in ${@} 
    do
        printf '\n%s\n' "Testing $bashver..."
        docker run bash:${bashver} --version
        time docker run\
            -v ${_rootVolume}:/opt/gabr/\
            bats/bats:bash-${bashver} --tap /opt/gabr/test
    done
)

function buildtest(){ # -- e.g. buildtest 3.2
    _supportedVersions ${@}
    build
    test
}
else
    echo $BASH_VERSION
    echo "To use ${BASH_SOURCE}, please update Bash to 4.3+" 1>&2
    return
fi