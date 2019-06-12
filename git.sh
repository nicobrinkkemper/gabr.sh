
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

function upstream() {
    git push --set-upstream origin $branch
}

function deleteStale() { # Useful when you see: stale (use 'git remote prune' to remove)
    # try 'git remote show origin' first
    git remote prune origin
}

function deleteLocalBranch() { # [local-branch] -- gabr git deleteLocalBranch some-feature
    git branch -d $1
    git branch -D $1
}

function deleteRemoteBranch() { # [remote-branch] -- gabr git deleteRemoteBranch some-feature
    git push $remote --delete $1
}

if ! [[ -v branch ]]; then
    declare branch=$(currentBranch)
fi
if ! [[ -v remote ]]; then
    declare remote=$(git remote)
fi