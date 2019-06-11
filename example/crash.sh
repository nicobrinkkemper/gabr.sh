if ! [[ -v args ]]; then
# when no arguments given, examplifies a crashing file
echo Crashing 1>&2
notfound
echo "Should stop at first hick-up, you shouldn't see this" 1>&2
return $?
fi

function badarray() {
   set -E
   mapfile foo < <(true; echo foo)
   echo ${foo[-1]} # foo
   mapfile foo < <(false; echo foo)
   echo ${foo[-1]} # bash: foo: bad arr
}

function subshellErr() {
    set -e
    mapfile foo < <(true; echo foo)
    echo ${foo[-1]} # foo
    mapfile foo < <(false; echo foo)
    echo ${foo[-1]} # bash: foo: bad array subscript
}

function die () { # -- e.g. gabr example human die
    echo "x_x" 1>&2
    return 1
}

function crashinsubshell () ( # -- e.g. gabr example human crashinsubshell
    notfound
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
)

function delayedcrashinsubshell () ( # -- e.g. gabr example human crashinsubshell
    crashinsubshell
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
)

function delayeddieinsubshell () ( # -- e.g. gabr example human delayeddieinsubshell
    sleep 1
    dieinsubshell
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
)

function dieinsubshell () ( # -- e.g. gabr example human dieinsubshell
    die
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
)

function delayeddieinsubshell () ( # -- e.g. gabr example human delayeddieinsubshell
    sleep 1
    dieinsubshell
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
)