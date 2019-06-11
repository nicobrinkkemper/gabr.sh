function root(){
    command git rev-parse --show-toplevel
}

function removeAllButMasterAndCurrentBranchLocally() {
    git branch | egrep -v "(master|\*)" | xargs git branch -D
}

function removeAllButRemoteMaster() {
    git remote update -p &&
    git branch -r --merged origin/master |
    grep origin |
    grep -v master |
    cut -d"/" -f2- |
}