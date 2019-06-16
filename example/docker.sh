
dir=$(git rev-parse --show-toplevel)
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
if ! [[ ${#bashvers[@]} -eq 0 ]]; then
    bashvers=(${!versions[@]})
fi

function build()(
    command docker build --build-arg bashver=${1:-$bashvers} --tag bats/bats:bash-${1:-$bashvers} .
)

function test()(
    command docker run -it bash:${1:-$bashvers} --version
    command time docker run -it bats/bats:bash-${1:-$bashvers} --tap /opt/gabr/test
)

function all(){
    if [[ $# -eq 0 ]]; then
        echo "Usage: ./docker.sh [versions] all [commands]"
        return 1
    fi
    while [ $# -ne 0 ]
    do
        $1
        shift
        if [ $# -ne 0 ]; then
            read -d y -p 'continue [y]'
        fi
    done
}