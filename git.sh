function root(){
    command git rev-parse --show-toplevel
}

function removeAllButMasterAndCurrentBranchLocally() {
    git branch | egrep -v "(master|\*)" | xargs git branch -D
}

function removeAllButRemoteMaster() {
    git branch -r --merged origin/master | grep -v master | grep "origin/" | cut -d "/" -f 3- | xargs -n 20 git push --delete origin
}