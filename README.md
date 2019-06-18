# Gabr.sh
[![npm package](https://img.shields.io/npm/v/gabr.sh.svg)](https://www.npmjs.com/package/gabr.sh)
[![Continuous integration status for Linux and macOS](https://travis-ci.org/nicobrinkkemper/gabr.sh.svg?branch=master&label=travis%20build)](https://travis-ci.org/bats-core/bats-core)
## Installation
### Try out as portable file
```shell
$ wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
$ source ./gabr.sh
```

### Install with git
```shell
$ git clone https://github.com/nicobrinkkemper/gabr.sh.git gabr
$ cd gabr
$ npm link
```
> When installed with `npm link`, `gabr` will run as a file.
> If you want to run `gabr` as a local function, try `source $(which gabr)`

### Install with npm
```shell
$ npm install --save-dev gabr
$ npm link gabr
```

## What is gabr.sh
Gabr is a Bash function designed to call other Bash functions.
Gabr takes arguments and will try to turn that in to a function call.
Gabr takes the path of least resistance towards a function call.
Let's illustrate that with a flowchart.

![Alt text](./Gabr.sh.svg)

Let's illustrate further with a code example. 
```shell
$ echo "\
printf hello
function helloworld() {
  printf ' world\n'
}
" > ./helloworld.sh
$ gabr helloworld
hello world
```
> By naming the file and the function helloworld,
> a tiny API emerged to call the function.

## Why use gabr.sh?
Consider the following commands to delete a tag with git:
```shell
git tag -d 1.0.1
git push origin :refs/tags/1.0.1
```
I'll be honest to myself and say I won't remember this next time.
Besides I have a lot of tags to delete.
I can just write a quick function.
```bash
set -eu
function deleteTag() {
    git tag -d $1
    git push origin :refs/tags/$1
}
```
To run this like `gabr` would, one could simply write:
```shell
$ (. git.sh; deleteTag 1.0.1)
```
But doing it like this is hard to communicate and prone to human error. With `gabr` a more direct API emerges to do these kind of things:
```
$ gabr git deleteTag 1.0.1
```

## Variables
### Local variables
Gabr defines the following local variables. These will be available in files sourced by Gabr. Variables that already exist will be inherited.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| env          	|       	| The strictness of the function           	| dev                                    	| May be set by `GABR_ENV`     	            |
| root         	|       	| The fallback directory                   	| $PWD                                   	| May be set by `GABR_ROOT`    	            |
| default      	|       	| Name of fallback function                	| usage                                  	| May be set by `GABR_ENV`              	|
| $default     	|       	| String printed by fallback function      	| $usage                                   	| See [Functions](#Functions)                     	|
| usage        	| -A    	| Usage string                            	| "Usage: gabr [file] function..."         	|                                          	|
| fn           	|       	| The called function                      	| usage                                  	|                                         	|
| args         	| -a    	| The arguments for the function           	| ()                                     	| Also available as ${@}                    |
| file        	|       	| The sourced file                       	|                                         	|                                         	|
| dir          	|       	| The relative directory of the file     	| .                                      	| Wil be cd'd to before calling the function|
| ext          	|       	| The extension to use       	            | .sh                                      	| Gabr also looks for files without extension|
| fullCommand  	|       	| The full initial command as string        | gabr ${@}                               	| Handy for custom `usage` implementations. See `./example/usage.md` |

### GABR_ENV / env
A global variable called `GABR_ENV` may be used to influence the value of `env`. `env`
controls the strictness with which `gabr` runs. Files and functions ran by `gabr` will
inherit this "strict-mode".

There are three valid values for `GABR_ENV`: `dev`, `prod` and `debug`.
Setting `GABR_ENV` to any other value will opt-out of strict-mode.

The behavior of the set builtin is complex. The [manual](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html) gives more detailed information, but here is a reminder:
 - **-e** Exit immediately on errors
 - **-E** Inherit traps
 - **(-x)** Enter debug mode
 - **-u** Error on unset variables
 - **-o pipefail** the return value is that of the last error

#### default (dev)
When running as a file, the following snippet is set before the `gabr` function is called:
```bash
set -eEuo pipefail
declare IFS=$'\n\t'
```

When running as a sourced function. `gabr` will postpone this snippet
until the subshell is entered. This will ensure the main shell won't
close (crash), but it will still fail early.

#### prod
Prod behaves similar to the default, with the addition of `set -e` inside
the main shell. When running as a file (`npm link`), this doesn't have any effect. 
When running as a sourced function, errors will close (crash) the shell.
```shell
$ export GABR_ENV=prod
```

#### debug
Debug is similar to default, with the addition of `set -x` before and `set +x` after every
file source and function call.
```shell
$ export GABR_ENV=debug
```

### GABR_ROOT / root
A global variable called `GABR_ROOT` may be used to influence the value of `root`. 
`root` is used as a fall-back directory. The fall-back directory will be consulted
when no other options are available.

```shell
$ export GABR_ROOT=$(git rev-parse --show-toplevel)
```
> This will make files at the root of a git repository available from anywhere

### GABR_DEFAULT / default
A global variable called `GABR_DEFAULT` may be used to influence the value of `default`. 
`default` may be used to change the namespace of the fall-back function.
```shell
$ export GABR_DEFAULT=help
```
> This will change `usage` to `help`. Also see [functions](#Functions)

## Functions

### function usage ()
By default, this function will be called as a last-resort:
```bash
local usage="gabr [directory | file] function [arguments] -- A function to call other functions."
function usage() {
    echo $usage >&2
}
```
> Feel free to overwrite this function and/or variable to extend
> usage behavior

### function $default ()

The namespace for `usage` may be altered with `GABR_DEFAULT` or simply `default`. If `default` is not set to `usage`, `gabr` generates a function and variable for this name. If a function or variable already exist with this name, these will be used instead. The generated function boils down to the following snippet:

```bash
$default=$usage
function $default() {
    echo ${!default} >&2
}
```
> The `!` introduces variable indirection. [Read more](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)

## Flags

Gabr does not require any flags. Gabr stops on any argument that starts with a dash (-).
