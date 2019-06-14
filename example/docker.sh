
dir=$(git rev-parse --show-toplevel)

function test(){
    if ! [[ -v BASHVERS ]]; then
        local BASHVERS=(3.2 4.0 4.1 4.2 4.3 4.4)
    fi
    if ! [[ $# -eq 0 ]]; then
        set -- $BASHVERS
    fi
    while [ $# -ne 0 ]
    do
        command docker build --build-arg bashver=${1} --tag bats/bats:bash-${1} .
        command docker run -it bash:${1} --version
        time docker run -it bats/bats:bash-${1} --tap /opt/gabr/test
        shift
        if [ $# -ne 0 ]; then
            read - 'continue?'
        fi
    done
}
