function laugh() { # -- e.g. gabr example human laugh
    echo ":D" >&2
    return
}

function smile() { # -- e.g. gabr example human smile
    echo ":)" >&2
    return
}

function cry() { # -- e.g. gabr example human cry
    echo ":'(" >&2
    return
}

function stare() { # -- e.g. gabr example human stare
    echo ":|" >&2
    return
}

function die () { # -- e.g. gabr example human die
    echo "x_x" 1>&2
    return 1
}

function delaydie(){
    gabr die
}

function delaycrash(){
    gabr crash
}

function crash () ( # -- e.g. gabr example human crash
    echo "x_x" 1>&2
    thisfunctionfails
)


usage="gabr example human <laugh|smile|cry|stare|crash> -- e.g. gabr example human"

if ! [[ -v args ]]; then
default=stickfigure # the default is 'usage'
function stickfigure() {
    echo "o|-<"  >&2
}
else
function human() {
    echo "Hi" >&2
    gabr debug ${@}
}
fi