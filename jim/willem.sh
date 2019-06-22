local here2=$PWD
function willem(){
    printf '%s ' "willem" >&2
    ! [ "$PWD" = "$here2" ] && return
    gabr bonito
}
