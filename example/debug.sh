
function debug(){
    if [ $# -eq 0 ]; then
        echo "Usage: gabr example debug [example-file] [example-function]"
        return
    fi
    GABR_DEBUG_MODE=true
    gabr $@
}