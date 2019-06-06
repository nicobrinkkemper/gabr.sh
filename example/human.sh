default=stickfigure # the default is 'usage'
usage="gabr example human <laugh|smile|cry|stare|crash> -- e.g. gabr example human"

function human() {
    echo "This is me" >&2
    gabr ${@}
}

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

function stickfigure() {
    echo "o|-<"  >&2
    return
}
