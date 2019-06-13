#!/usr/bin/env bash
# @file git.sh
#
# @brief  Git.sh contains some one-off git functions. To serve as example.

# @description Gets the current branch
# @example
#   $ gabr example git currentBranch
#   master
function currentBranch() {
    local branch
    branch="$(git symbolic-ref HEAD 2>/dev/null)" || branch="undefined"
    branch=${branch##refs/heads/}
    echo $branch
}

# @description Returns root of git repository
# @example
#   $ gabr example git root
#   ~/Code/your/project
function root(){
    command git rev-parse --show-toplevel;
}


# @description Deletes a local branch
# @example
#   $ gabr example git deleteBranch
function deleteBranch() {
    git branch -d $branch
    git branch -D $branch
}

# @description Sets current branch to upstream
# @example
#   $ gabr example git upstream
# @arg $branch A variable to set origin to (default:current)
function upstream() {
    git push --set-upstream origin $branch
}

# @description Deletes stale branches
# Useful when you see: `stale (use 'git remote prune' to remove)`
#
# To maybe see this message pop-up, run `git remote show origin`
# @example
#   $ gabr example git deleteStale
function deleteStale() { 
    git remote prune origin
}

# @description Checkout other branch (e.g. master) then delete previous active branch
# @example
#   $ gabr example git deleteLocalBranch feature-branch
# @arg string [ $1 ]          existing-checkout-branch (default:master) -- e.g. develop
# @arg string [ $2 | $branch ]  to-delete-branch-name (default:current) -- e.g. feature-branch
# @arg string [ $3 | $remote ]  to-delete-remote (default:current) -- e.g. origin
function deleteBranch() {
    local checkout=${1:-master}
    local branch=${2:-$branch}
    local remote=${3:-remote}
    if [[ ${checkout} = ${branch} ]]; then
        echo "Checkout branch may not be the same as deleted branch" 1>&2
        return 1
    fi
    git checkout $checkout
    git branch -d $branch
    git branch -D $branch
    git push $remote --delete $1
}

# @description Delete a remote branch
# @example
#       gabr example git deleteTag some-feature
# @arg $1 version
function deleteTag() {
    git tag -d $1
    git push origin :refs/tags/$1
}

if ! [[ -v branch ]]; then
    declare branch=$(currentBranch)
fi
if ! [[ -v remote ]]; then
    declare remote=$(git remote)
fi