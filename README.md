# Gabr.sh
[![npm package](https://img.shields.io/npm/v/gabr.svg)](https://www.npmjs.com/package/gabr)
[![Continuous integration status for Linux and macOS](https://travis-ci.org/nicobrinkkemper/gabr.sh.svg?branch=master&label=travis%20build)](https://travis-ci.org/nicobrinkkemper/gabr.sh)
## Installation
### Try out as portable file
```shell
$ wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
$ source ./gabr.sh
```

### Install with git
```shell
$ git clone --recursive https://github.com/nicobrinkkemper/gabr.sh.git gabr
$ cd gabr
$ npm link
```
> The recursive flag is optional, allows you to run tests

### Install with npm
```shell
$ npm install --save-dev gabr
$ npm link gabr
```
> If you want to run `gabr` as a local function, try `. gabr`

## What is gabr.sh
Gabr is a Bash function designed to call other Bash functions.
Gabr takes arguments and will try to turn that in to a function call.
Gabr takes the path of least resistance towards a function call.
Let's illustrate that with a flowchart.

![Alt text](./Gabr.sh.svg)

> When a argument is neither a function, file or directory a warning will show and the process is stopped.
> For this reason `set -- usage` runs only when the `gabr` function is called
> without any arguments, or a directory is called without arguments.
> Sourcing a file is a success, and thus `usage` will not be set.

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
Gabr defines the following local variables.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| default      	|       	| Name of fallback namespace              	| usage                                  	| May be set by `GABR_DEFAULT`            	|
| usage        	|       	| Usage string                            	| "Usage: gabr [file] function..."         	|                                          	|
| $default     	|       	| String printed by fallback function      	| $usage                                   	| See [Functions](#Functions)              	|
| fn           	|       	| The called function                      	|                                     	    |                                     	    |
| args         	| -a    	| The left-over arguments                   | ()                                     	| Available as ${@} in target files/functions|
| prevArgs      | -a    	| The successful arguments                  | ()                                     	|                                           |
| file        	|       	| The sourced file                       	|                                         	| Will be unset after file is sourced   	|
| dir          	|       	| The relative directory of the file     	| .                                      	| Wil be cd'd to before calling the function|
| ext          	|       	| The extension to use       	            | .sh                                      	| Gabr also looks for files without extension|
| FUNCNEST     	|       	| See manual ([reference](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)) | 50 | Prohibits overly recursive function calls

### Global variables
### GABR_STRICT_MODE (default:on)
A global variable called `GABR_STRICT_MODE` may be used to toggle the following snippet:
```bash
set -eEuo pipefail
local IFS=$'\n\t'
trap 'return $?' ERR SIGINT
```
This snippet will run once inside the subshell where the function is called and the file is sourced.
Let's go over the three lines:

1)
    `set` allows you to change the values of shell options and set the positional parameters, or to display the names and values of shell variables. ([reference](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html))
    - **-x** Enter debug mode
    - **-e** Exit immediately on errors
    - **-E** Inherit traps
    - **-u** Error on unset variables
    - **-o pipefail** the return value is that of the last error
    
1)  `IFS` is a string treated as a list of characters that is used for field splitting.
    By default, this is set to \<space> \<tab> \<newline>. \<space> causes issues when entering 
    arguments that contain spaces, such as sentences. This is why `IFS` is set to
    \<tab> \<newline> in strict-mode. ([reference](https://pubs.opengroup.org/onlinepubs/9699919799.2018edition/utilities/V3_chap02.html#tag_18_05_03))
    
3)
    If `return` is executed by a `trap ERR` handler, the last command used to determine the non-zero status is the last command executed before the trap handler. `trap 'return $?' ERR` will ensure the conditions obeyed by the errexit (-e) option for  older Bash versions. Furthermore, `SIGINT` will be handled the same way, which allows a user to interrupt (ctrl+C) any long running script. ([reference](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html))

To opt-out of strict-mode:
```shell
$ export GABR_STRICT_MODE=off
```

### GABR_DEBUG_MODE
Setting this variable to a value will turn on debug mode for files and functions.
The `gabr` function will do `set -x` before and `set +x` after every
file source and function call.
```shell
$ export GABR_DEBUG_MODE=true
```

This variable is useful, because it omits `gabr` debug info from polluting a users code.

### GABR_ROOT / root
If `GABR_ROOT` is set to a value the `gabr` function will change directory
to this location on every invocation.
```shell
$ export GABR_ROOT=$(git rev-parse --show-toplevel)
```
> This will make files at the root of a git repository accessible to the `gabr` function

This variable is powerful, it will make arguments put in more likely to result
in the same output. Keep in mind that the `gabr` function will lose it's flexibility,
it will always run from a fixed location.

### GABR_DEFAULT
A global variable called `GABR_DEFAULT` may be used to influence the default namespace. 
By default this namespace is `usage`. The default namespace is consulted when no other options are found. 
If neither a default function nor a default file is found, a default function will be generated. (see [functions](#Functions))

```shell
$ export GABR_DEFAULT=index
```
> This will make `index.sh` behave similar to index-files in other programming languages.

This variable is useful, but the default value `usage` is probably the way to go. 

## Functions

### function usage ()
If all else fails, a last-resort function will be generated. By default it's this
snippet.
```bash
local usage="gabr [directory | file] function [arguments] -- A function to call other functions."
function usage() {
    echo $usage >&2
}
```
If a file is sourced that doesn't contain a function with the same name.
The following snippet could benefit end-users.

```bash
if [ $# -eq 0 ]; then
    usage='help-info-for-this-file'
    set -- usage
fi
```
Or as a function

```bash
if [ $# -eq 0 ]; then
    set -- usage
fi
function usage(){
    echo 'help-info-for-this-file'
}
```

### function $default ()
The namespace for `usage` may be altered with `GABR_DEFAULT` or simply `default`.
If `default` is not set to `usage`, `gabr` generates a last-resort function and variable for this name instead.
This is done through variable indirection. ([reference](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html))
To generate a function with a dynamic name a small eval trick is used. For this reason
the default variable may not contain special-characters.

In most cases, the following snippet would suffice for files that don't contain a function
with the same name:
```bash
if [ $# -eq 0 ]; then
    set -- otherUsage
fi
otherUsage(){
    "help-info-for-this-file"
}
```
But you can take it further by changing `gabr`'s default variable.
```bash
if [ $# -eq 0 ]; then
    default=otherUsage
    otherUsage="help-info-for-this-file"
    set -- $default
fi
```
> This will print `$otherUsage` inside a generated function


## Flags

Gabr does not require any flags. Gabr stops on any argument that starts with a dash (-).
