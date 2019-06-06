if ! [[ -v args ]]; then
function example(){ # 
    echo "This is a example" >&2
}
fi

function usage() {
    echo "gabr example <function> -- e.g. gabr example crash"
}

function scope() { # lists current function scope in which the function runs -- e.g. gabr example scope
    IFS=$'\n'
    for f in ${stack}; do
        echo "${f:11}"
    done
}


function passtrough() {
    echo "Passing through" >&2
    gabr
}

function passtroughhuman() { # exemplifies recursive gabr calls -- e.g. gabr example passtroughhuman
    echo "Passing through" >&2
    gabr human
}