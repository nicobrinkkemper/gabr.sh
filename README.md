# Gabr.sh
[![npm package](https://img.shields.io/npm/v/gabr.sh.svg)](https://www.npmjs.com/package/gabr.sh)
[![Continuous integration status for Linux and macOS](https://travis-ci.org/nicobrinkkemper/gabr.sh.svg?branch=master&label=travis%20build)](https://travis-ci.org/bats-core/bats-core)
## Installation
```shell
$ source ./gabr.sh
```
> Grab the files however you want

### Install as node_module
```shell
$ npm install --save-dev gabr.sh
$ npm link
$ source $(which gabr)
```
> The source step will give the `gabr` function access to local variables. Which is
> used in some of the examples below.
> When running as a file instead, remember to `export` the variables.

## What is gabr.sh
Gabr is a Bash function designed to call other Bash functions.
Gabr takes arguments and will try to turn that in to a function call.
Gabr takes the path of least resistance towards a function call.
Let's illustrate that with a flowchart.

![Alt text](./Gabr.sh.svg)


## Variables

### Variables
Gabr defines some useful variables.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| GABR_ENV     	|       	| A global value for `env`                 	|                                        	|                                         	|
| env          	|       	| The strictness of the function           	| dev                                    	|                                         	|
| GABR_ROOT    	|       	| A global value for `root`                	|                                        	|                                         	|
| root         	|       	| The fallback directory                   	| $PWD                                   	|                                         	|
| GABR_DEFAULT 	|       	| A global value for `default`             	|                                        	|                                         	|
| default      	|       	| Name of fallback function                	| usage                                  	|                                         	|
| $default     	|       	| String printed by fallback function      	| "Usage: gabr [file] function..."       	| created through variable indirection    	|
| files        	| -A    	| All included files                       	| ()                	| BASH 4.3+                               	|
| file         	|       	| Recently imported file                   	|                                        	|                                         	|
| filename     	|       	| Recently imported file without extension 	|                                        	|                                         	|
| fn           	|       	| The called function                      	| usage                                  	|                                         	|
| args         	| -a    	| The arguments for the function           	| ()                                     	| Also available as ${@} in sourced files 	|
| dir          	|       	| The directory to run the function in     	| .                                      	|                                         	|

### env (default:dev)
```shell
$ GABR_ENV=dev
# or
$ env=dev
```
> `set -Euo pipefail` at subshell level *(default)*
>
> Will exit a subshell on errors (non-zero return/unbound variables)
```shell
$ export GABR_ENV=debug
# or
$ env=debug # as local variable
```
> Print debug information
```shell
$ export GABR_ENV=prod
# or
$ env=prod
```
> `set -euo pipefail` at shell level
> 
> Will exit both shell and subshell on errors
```shell
$ export GABR_ENV=none
# or
$ env=none
```
> Any other value than `dev`, `prod`, or `debug` opts-out of above rules

### root (default:current PWD)
```shell
$ export GABR_ROOT=$PWD # fix root to current PWD (even after cd'ing)
# or
$ export GABR_ROOT=./scripts/ # fix root to local scripts folder
# or
$ root=./your/path # same as above, but as local variable
```
> This allows for a utility directory that is always available

### default (default:usage)
```shell
$ export GABR_DEFAULT=help # usage becomes help
# or
$ default=help # same as above, but as local variable
```
> A default function will be generated but can be overwritten or inherited.
> 
> The default function will echo a variable with the same name. Which
> can also be overwritten or inherited. This is done through variable indirection in Bash 4.3+
> and `eval` in Bash 3.2+.

### dir (default:.)
```shell
$ dir=./scripts # scripts becomes the target directory for the file
```
> `dir` will be `cd`'d to before calling a function. It's
> handy to set this variable in a file. All functions in that file will be called in
> that directory.

### debug
```shell
$ debug=(fn) # gabr will enter debug mode and print information about fn
# and
$ unset debug # gabr will exit debug mode
```
> This allows to debug any value.
> 
> Keep in mind though that arrays are not exportable. This won't work from a
> terminal in combination with `npm link`. Instead source the script in a terminal,
> or use `export GABR_ENV=debug`.

## Flags

Gabr does not require any flags. The flags will be automatically assigned
based on user input. Only one argument is needed to call a function if files and directories are named a like. Nonetheless, they can still provide information.

#### --file
A full path to a file. This flag will be derived if a argument is a valid
path to a file. If the argument is a valid function name after source, it will
be called.

#### --derive
A name of a file without extension. This flag will be derived if a file
exists. If the argument is a valid function name after source, it will
be called.


## Example
This example assumes you have the gabr function sourced.
```shell
$ function debug(){
  declare -p $@
}
```
> Write a simple function

```shell
$ gabr debug BASH_VERSION BASH_SOURCE
# declare -- BASH_VERSION="4.4.19(1)-release"
# declare -a BASH_SOURCE=([0]="main" [1]="/home/usr/.nvm/versions/node/v11.7.0/bin/gabr.linux")
```
> Right. It called that function on the spot

```shell
$ declare -f debug > ./debug.sh
$ unset -f debug
```
> Put the function in a file and unset it

```shell
$ gabr debug BASH_SOURCE
# declare -a BASH_SOURCE=([0]="./debug.sh" [1]="/home/usr/.nvm/versions/node/v11.7.0/bin/gabr.linux")
```
> Right, it still called it. Now let's debug something.

```shell
$ echo "\
debug=(args) # 
function badarray() {
    mapfile foo < <(true; echo foo)
    echo \${foo[-1]:-} >&2 # foo
    mapfile foo < <(false; echo foo)
    echo \${foo[-1]:-} >&2
}
" > ./debug.sh
```
> This would be a nasty case to debug 

```shell
$ gabr debug badarray
# args=([0]="badarray")
# -----------
# Calling badarray
foo
./debug.sh: line 6: foo: bad array subscript
```
> Fair enough. Gabr debugged it by not debugging it.
> For more examples, checkout the example directory.


### Miscellaneous Variables

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| prevFn       	|       	| The previous value of fn                 	|                                        	|                                         	|
| primaryFn    	|       	| The first argument                       	| $1                                     	|                                         	|
| error        	| -a    	| The error messages                       	| ()                                     	| Will be printed on internal errors      	|
| exitcode     	|       	| The error exitcode                       	|                                        	| Set on ERR SIGINT trap                  	|
| wrapInfo     	|       	| `printf` helper for debug messages       	| "# "%s'\n'                             	| # some message                          	|
| wrapErr      	|       	| `printf` helper for error messages       	| $'\033[0;91m'"Warning: "%s$'\033[0m\n' 	| Warning: light red color                	|
| pwd          	|       	| Initial directory                        	|                                        	| Not used internally                     	|
| funcname     	| -a    	| Initial previously called functions      	| ${FUNCNAME[@]}                         	| Not used internally                     	|
| stack        	|       	| Initial available functions              	|                                        	| Not used internally                     	|
