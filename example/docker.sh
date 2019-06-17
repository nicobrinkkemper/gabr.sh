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
local -a bashvers=()
while [[ -v versions["${1:-}"] ]]
do
    echo Added version ${1} 2>&2
    bashvers+=(${versions["${1}"]})
    shift
done
if [[ $# -eq 0 ]]; then
    set  -- usage
    local usageFiles=" [$( echo ${!versions[@]} | tr ' ' '|')]"
else
    dir=$(git rev-parse --show-toplevel) # functions target root directory
fi
if ! [[ ${#bashvers[@]} -eq 0 ]]; then
    bashvers=(${!versions[@]})
fi

function build()(
    command docker build --build-arg bashver=${1:-$bashvers} --tag bats/bats:bash-${1:-$bashvers} .
)

function test()(
    command docker run -it bash:${1:-$bashvers} --version
    command time docker run\
        -v $(pwd):/opt/gabr/\
        -it bats/bats:bash-${1:-$bashvers} --tap /opt/gabr/test
)

function buildtest(){ # -- e.g. gabr docker 3.2 buildtest
    build;
    test;
}
else
    echo "To use ${BASH_SOURCE}, please update Bash to 4.3+" 1>&2
    return
fi