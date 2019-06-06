if ! [[ -v args ]]; then
function example(){ # 
    echo "This is a example" >&2
}
else
usage() {
    echo "gabr example <function> -- e.g. gabr example crash"
}
fi

function passtrough() {
    echo "Passing through" >&2
    gabr
}

function scope() { # lists current function scope in which the function runs -- e.g. gabr example scope
    IFS=$'\n'
    for f in $(declare -F); do
    echo "${f:11}"
    done
}

function die () { # -- e.g. gabr example human die
    echo "x_x" 1>&2
    return 1
}

function crash() { # exemplifies crash prevention depending on GABR_ENV -- e.g. gabr example crash
    echo Crashing 1>&2
    false
    fewf
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
    return $?
}

function passtroughhuman() { # exemplifies recursive gabr calls -- e.g. gabr example passtroughhuman
    echo "Passing through" >&2
    gabr human
}