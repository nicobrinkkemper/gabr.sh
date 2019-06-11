
function currentBranch() {
    local branch
    branch="$(git symbolic-ref HEAD 2>/dev/null)" || branch="undefined"
    branch=${branch##refs/heads/}
    echo $branch
}

function root(){
    command git rev-parse --show-toplevel
}

function branchRef() {
    command git symbolic-ref HEAD
}

function deleteBranch() {
    git branch -d $branch
    git branch -D $branch
}

function deleteBranch() {
    git branch -d $1
    git branch -D $1
}

if ! [[ -v branch ]]; then
    declare branch=$(currentBranch)
fi