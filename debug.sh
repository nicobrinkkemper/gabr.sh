debug=(args)
function badarray() {
    mapfile foo < <(true; echo foo)
    echo ${foo[-1]:-} >&2 # foo
    mapfile foo < <(false; echo foo)
    echo ${foo[-1]:-} >&2 # will print: ./debug.sh: line 9: foo: bad array subscript
}

