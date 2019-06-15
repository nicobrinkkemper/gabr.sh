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
> used in some of the examples in [/example](./example).
> When running as a file instead, remember to `export` the variables.

## What is gabr.sh
Gabr is a Bash function designed to call other Bash functions.
Gabr takes arguments and will try to turn that in to a function call.
Gabr takes the path of least resistance towards a function call.
Let's illustrate that with a flowchart.

![Alt text](./Gabr.sh.svg)


## Variables

### GABR_ENV
```shell
$ export GABR_ENV=dev
```
> `set -Euo pipefail` at subshell level *(default)*
>
> Will exit subshell on errors (non-zero return/unbound variables)
```shell
$ export GABR_ENV=debug
```
> Print debug information
```shell
$ export GABR_ENV=prod
```
> `set -euo pipefail` at shell level
> 
> Will exit both shell and subshell on errors
```shell
$ export GABR_ENV=none
```
> Any other value than `dev`, `prod`, or `debug` opts-out of above rules

### GABR_ROOT
```shell
$ export GABR_ROOT=$PWD # fix root to current PWD (even after cd'ing)
```
> This allows for a utility directory that is always available

### GABR_DEFAULT
```shell
$ export GABR_DEFAULT=help # usage becomes help
```
> A default function will be generated but can be overwritten or inherited.
> 
> The default function will echo a variable with the same name. Which
> can also be overwritten or inherited. This is done through variable indirection in Bash 4.3+
> and `eval` in Bash 3.2+.

### Variables
Gabr defines some useful variables. These will be available in files sourced by Gabr.
If any of these already exist, they will be inherited.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| env          	|       	| The strictness of the function           	| dev                                    	|                                         	|
| root         	|       	| The fallback directory                   	| $PWD                                   	|                                         	|
| default      	|       	| Name of fallback function                	| usage                                  	|                                         	|
| $default     	|       	| String printed by fallback function      	| "Usage: gabr [file] function..."       	| created through variable indirection    	|
| files        	| -A    	| All included files                       	| ()                	| BASH 4.3+                               	|
| file         	|       	| Recently imported file                   	|                                        	|                                         	|
| filename     	|       	| Recently imported file without extension 	|                                        	|                                         	|
| fn           	|       	| The called function                      	| usage                                  	|                                         	|
| args         	| -a    	| The arguments for the function           	| ()                                     	| Also available as ${@} in sourced files 	|
| dir          	|       	| The directory to run the function in     	| .                                      	|                                         	|

### Miscellaneous Variables
These values wil be available in sourced files.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| prevFn       	|       	| The previous value of fn                 	|                                        	|                                         	|
| error        	| -a    	| The error messages                       	| ()                                     	| Will be printed on internal errors      	|
| exitcode     	|       	| The error exitcode                       	|                                        	| Set on ERR SIGINT trap                  	|
| wrapInfo     	|       	| `printf` helper for debug messages       	| "# "%s'\n'                             	| # some message                          	|
| wrapErr      	|       	| `printf` helper for error messages       	| $'\033[0;91m'"Warning: "%s$'\033[0m\n' 	| Warning: light red color                	|
| primaryFn    	|       	| The first argument                       	| $1                                     	| Not used internally                      	|
| pwd          	|       	| Initial directory                        	|                                        	| Not used internally                     	|
| funcname     	| -a    	| Initial previously called functions      	| ${FUNCNAME[@]}                         	| Not used internally                     	|
| stack        	|       	| Initial available functions              	| declare -F                             	| Not used internally                     	|

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