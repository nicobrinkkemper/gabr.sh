function usage(){
    printf '%s' "\
Thank you for using gabr. This is the usage message for the git repository.
This message should only show up if you are located in this repository and typed 'gabr'
Try out:
    - gabr example
    - gabr example human smile
    - gabr test
    - gabr example docker test 3.2
Usage: ${usage:-'not set'}" >&2
    if [ -n "${GABR_ROOT:-}" ]; then
        printf '%s\n' "\
# You might be seeing this message because GABR_ROOT=$GABR_ROOT. It doesn't have to be set 
to the location of this repository, but your own." >&2
    fi
}