# git.sh

 Git.sh contains some one-off git functions. To serve as example.

* [currentBranch()](#currentBranch)
* [deleteBranch()](#deleteBranch)
* [upstream()](#upstream)
* [deleteStale()](#deleteStale)
* [deleteBranch()](#deleteBranch)
* [deleteRemoteBranch()](#deleteRemoteBranch)


## currentBranch()

Gets the current branch
### Example

```bash
$ gabr git currentBranch
master
```

## deleteBranch()

Deletes a local branch
### Example

```bash
$ gabr git deleteBranch
```

## upstream()

Sets current branch to upstream
### Example

```bash
$ gabr git upstream
```

### Arguments

* $branch A variable to set origin to (default:current)

## deleteStale()

Deletes stale branches
Useful when you see: `stale (use 'git remote prune' to remove)`

To maybe see this message pop-up, run `git remote show origin`
### Example

```bash
$ gabr git deleteStale
```

## deleteBranch()

Checkout other branch (e.g. master) then delete previous active branch
### Example

```bash
$ gabr git deleteLocalBranch feature-branch
```

### Arguments

* string [ $1 ]          existing-checkout-branch (default:master) -- e.g. develop
* string [ $2 | $branch ]  to-delete-branch-name (default:current) -- e.g. feature-branch
* string [ $3 | $remote ]  to-delete-remote (default:current) -- e.g. origin

## deleteRemoteBranch()

Delete a remote branch
### Example

```bash
    gabr git deleteRemoteBranch some-feature
```

### Arguments

* **$1** (remote-branch):
* $2|$remote a variable to control remote branch (default:current)

