# Gabr.sh
[![npm package](https://img.shields.io/npm/v/gabr.sh.svg)](https://www.npmjs.com/package/gabr.sh)
[![Continuous integration status for Linux and macOS](https://travis-ci.org/nicobrinkkemper/gabr.sh.svg?branch=master&label=travis%20build)](https://travis-ci.org/bats-core/bats-core)

## Installation
### Install as node_module
```shell
$ npm install --save-dev gabr.sh
$ npm link
```
### Install as file
```shell
$ wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
$ source ./gabr.sh
```
## What is gabr.sh
Gabr is a Bash function designed to call other Bash functions.
Gabr takes arguments and will try to turn that in to a function call.

## Usage
```
gabr [--file] [--derive] [file] function [arguments] -- A function to call other functions
    --file       A full path to a file
    --derive     A filename without extension
    1..N         Performs various checks to derive flags
                 Flags are optional and not needed in most cases
```
## Example
```
function helloworld(){
  echo hello world
}
source gabr.sh
gabr helloworld
```
> Right. But that's just helloworld with extra steps! Yes,
but gabr doesn't care. If it's a function, it will call it. This
just proofs that. Now if you put it in a file called `helloworld.sh`,
the command won't change. And you can go further and put it in a 
directory called `helloworld`. To see this in code, see [HELLOWORLD.md](./examples/HELLOWORLD.md) 

## Variables
### env (default:dev)
```shell
GABR_ENV=dev
# or
env=dev
```
> `set -Euo pipefail` at subshell level *(default)*
>
> Will exit a subshell on errors (non-zero return/unbound variables)
```
GABR_ENV=debug
# or
env=debug
```
> Print helpful debug information
```shell
GABR_ENV=prod
# or
env=prod
```
> `set -euo pipefail` at shell level
> 
> Will exit both shell and subshell on errors
```shell
GABR_ENV=none
# or
env=none
```
> Any other value than `dev`, `prod`, or `debug` opts-out of above rules

### root (default:current PWD)
```shell
GABR_ROOT=$PWD # fix root to current PWD (even after cd'ing)
# or
root=$PWD # same as above
# or
GABR_ROOT=./scripts/ # fix root to local scripts folder
```
> This allows for a utility directory that is always available

### default (default:usage)
```shell
GABR_DEFAULT=help # usage becomes help
# or
default=help # same as above
```
> A default function will be generated but can be overwritten or inherited.
> 
> The default function will echo a variable with the same name. Which
> can also be overwritten or inherited.

### dir (default:.)
```shell
dir=./scripts # scripts becomes the target directory for the file
```
> Changing `dir` during `source` can help keep your files in one directory but still couple them to a specific directory.

### debug
```shell
debug=(fn) # gabr will enter debug mode and print information about fn
# and
unset debug # gabr will exit debug mode
```
> This allows to debug any value, even your own.

#### And more
Checkout the code, after all it's just one function. You can inherit or overwrite other variables but they will make less sense than the afore mentioned.

## Flags

Gabr does not require any flags. The flags will be automatically assigned
based on user input. Only one argument is needed to call a function if files and directories are named a like.

#### --file
A full path to a file. This flag will be derived if a argument is a valid
path to a file.

#### --derive
A name of a file without path and .sh extension. This flag will be derived if a file
exists. The file must have a .sh extension.
