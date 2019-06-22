local here1=$PWD
function jim(){
    printf '%s ' "jim" >&2
    ! [ "$PWD" = "$here1" ] && return
    gabr willem
}
