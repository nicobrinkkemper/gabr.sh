# Gabr.sh
[![npm package](https://img.shields.io/npm/v/gabr.sh.svg)](https://www.npmjs.com/package/gabr.sh)
[![Continuous integration status for Linux and macOS](https://travis-ci.org/nicobrinkkemper/gabr.sh.svg?branch=master&label=travis%20build)](https://travis-ci.org/nicobrinkkemper/gabr.sh)
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
| root         	|       	| The fallback directory                   	| $PWD                                   	| May be set by `GABR_ROOT`    	            |
| default      	|       	| Name of fallback function                	| usage                                  	| May be set by `GABR_MODE`              	|
| $default     	|       	| String printed by fallback function      	| $usage                                   	| See [Functions](#Functions)                     	|
| usage        	| -A    	| Usage string                            	| "Usage: gabr [file] function..."         	|                                          	|
| fn           	|       	| The called function                      	| usage                                  	|                                         	|
| args         	| -a    	| The arguments for the function           	| ()                                     	| Also available as ${@}                    |
| file        	|       	| The sourced file                       	|                                         	|                                         	|
| dir          	|       	| The relative directory of the file     	| .                                      	| Wil be cd'd to before calling the function|
| ext          	|       	| The extension to use       	            | .sh                                      	| Gabr also looks for files without extension|
| fullCommand  	|       	| The full initial command as string        | gabr ${@}                               	| Handy for custom `usage` implementations. See `./example/usage.md` |

### GABR_MODE / mode
A global variable called `GABR_MODE` may be used to influence the value of `mode`. `mode`
influences some common -opinionated- defaults. Files and functions ran by `gabr` will inherit this strictness. Let's call this strict-mode.

There are two valid values for `GABR_MODE`: `strict` and `debug`.
Each of these values will make the `gabr` function run in strict-mode.
Setting `GABR_MODE` to any other value will opt-out of strict-mode.

### Strict-mode
`gabr`'s strict-mode consists of slight variations of the following snippet:
```bash
1 set -eEuo pipefail # and: set -x
2 IFS=$'\n\t'
3 trap 'return $?' ERR SIGINT # or exit when run as file
```
Let's go over the three lines:

1)
    `set` allows you to change the values of shell options and set the positional parameters, or to display the names and values of shell variables. ([reference](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html))
    - **-x** Enter debug mode
    - **-e** Exit immediately on errors
    - **-E** Inherit traps
    - **-u** Error on unset variables
    - **-o pipefail** the return value is that of the last error
    
2)
    `IFS` is a string treated as a list of characters that is used for field splitting.
    By default, this is set to \<space> \<tab> \<newline>. Spaces cause issues when entering 
    arguments that resemble human language. This is why `IFS` is set to
    \<tab> \<newline> in strict-mode. ([reference](https://pubs.opengroup.org/onlinepubs/9699919799.2018edition/utilities/V3_chap02.html#tag_18_05_03))s
3)
    If `return` is executed by a `trap ERR` handler, the last command used to determine the non-zero status is the last command executed before the trap handler. They will ensure the conditions obeyed by the errexit (-e) option. This is mainly to support older Bash versions. Furthermore, `SIGINT` will be handled the same way, which allows a user to interrupt (ctrl+C) any long running script. ([reference](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html))

#### debug-mode
debug-mode is similar to strict-mode, with the addition of `set -x` before and `set +x` after every
file source and function call.
```shell
$ export GABR_MODE=debug
```

#### opt-out
To opt-out of strict-mode, try setting `GABR_MODE` to any other value.
```shell
$ export GABR_MODE=none
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
