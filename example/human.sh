#!/usr/bin/env bash
if [[ $# -eq 0 ]]; then
    set -- usage
fi
echo "This is human" >&2

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