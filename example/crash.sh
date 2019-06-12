function badarray() { # -- e.g. gabr example badarray; echo $?
    mapfile foo < <(true; echo foo)
    echo ${foo[-1]:-} >&2 # foo
    mapfile foo < <(false; echo foo)
    echo ${foo[-1]:-} >&2 # will print: ./example/crash.sh: line 15: foo: bad array subscript
}

function die () { # -- e.g. gabr example crash die; echo $?
    echo "x_x" 1>&2
    return 1
}

function notfound () { # -- e.g. gabr example crash die; echo $?
    thiscommandisnotfound
}

if ! [[ -v args ]]; then
# when no arguments given, examplifies a crashing file
echo Crashing 1>&2
die
echo "Should stop at first hick-up, you shouldn't see this" 1>&2
fi