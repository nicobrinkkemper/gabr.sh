
function die () { # -- e.g. gabr example human die
    echo "x_x" 1>&2
    return 1
}

function crash() { # exemplifies crash prevention depending on GABR_ENV -- e.g. gabr example crash
    echo Crashing 1>&2
    notfound
    fewf
    echo "Should stop at first hick-up, you shouldn't see this" 1>&2
    return $?
}

function crashinsubshell () ( # -- e.g. gabr example human crashinsubshell
    crash
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