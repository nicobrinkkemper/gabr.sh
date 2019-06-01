
function example() {
    echo "This is a example" >&2
    if [[ $# -eq 0 ]]; then
        return
    fi
    gabr ${@}
}