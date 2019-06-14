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
directory called `helloworld`. To see this in code, see [HELLOWORLD.md](./example/HELLOWORLD.md) 

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
```shell
export GABR_ENV=debug
# or
env=debug # as local variable
# or
debug=(fn args dir) # same effect, but gives more control over which variables to debug
# keep in mind arrays are not exportable variables.
```
> Print helpful debug information
```shell
export GABR_ENV=prod
# or
env=prod
```
> `set -euo pipefail` at shell level
> 
> Will exit both shell and subshell on errors
```shell
export GABR_ENV=none
# or
env=none
```
> Any other value than `dev`, `prod`, or `debug` opts-out of above rules

### root (default:current PWD)
```shell
export GABR_ROOT=$PWD # fix root to current PWD (even after cd'ing)
# or
export GABR_ROOT=./scripts/ # fix root to local scripts folder
# or
root=./your/path # same as above, but as local variable
```
> This allows for a utility directory that is always available

### default (default:usage)
```shell
export GABR_DEFAULT=help # usage becomes help
# or
default=help # same as above, but as local variable
```
> A default function will be generated but can be overwritten or inherited.
> 
> The default function will echo a variable with the same name. Which
> can also be overwritten or inherited.

### dir (default:.)
```shell
dir=./scripts # scripts becomes the target directory for the file
```
> `dir` will be `cd`'d to before calling a function. It's
> handy to define this variable in a file. All functions in that file will be called in
> that directory.

### debug
```shell
debug=(fn) # gabr will enter debug mode and print information about fn
# and
unset debug # gabr will exit debug mode
```
> This allows to debug any value, even your own, or system variables.
> 
> Keep in mind though that arrays are not exportable. This won't work from your
> terminal in combination with `npm link`. Instead source the script in terminal,
> or use `export GABR_ENV=debug`.

#### And more
Gabr defines some useful variables. Here is a list of all the variables that can be inherited by gabr.

| variable  	| type 	| description                               	| default                                       	| Note                               	|
|-----------	|------	|-------------------------------------------	|-----------------------------------------------	|------------------------------------	|
| files     	| -A   	| All included files                        	| ([./gabr.sh]=./gabr.sh)                       	| BASH 4.3+                          	|
| file      	|      	| Recently imported file with extension     	|                                               	|                                    	|
| filename  	|      	| Recently imported file without extension  	|                                               	|                                    	|
| pwd       	|      	| The starting directory                    	| $PWD                                          	| Not used internally                	|
| prevFn    	|      	| The previous value of fn                  	|                                               	|                                    	|
| primaryFn 	|      	| The first argument to be received by Gabr 	| $1                                            	|                                    	|
| fn        	|      	| The called function                       	| usage                                         	|                                    	|
| args      	| -a   	| The arguments for the function            	| ()                                            	|                                    	|
| dir       	|      	| The directory to run the function in      	| .                                             	|                                    	|
| error     	| -a   	| The error messages                        	| ()                                            	| Will be printed on internal errors 	|
| exitcode  	|      	| The error exitcode                        	|                                               	| Set on ERR SIGINT trap             	|
| funcname  	| -a   	| Initial previously called functions       	| ${FUNCNAME[@]}                                	| Not used internally                	|
| stack     	|      	| Initial available functions               	| declare -F                                    	| Not used internally                	|
| wrapInfo  	|      	| `printf` helper for debug messages        	| "# "%s'\n'                                    	| # some message                     	|
| wrapErr   	|      	| `printf` helper for error messages        	| $' \033 [0;91m'"Warning: " %s$' \033 [0m \n ' 	| Warning: light red color           	|


## Flags

Gabr does not require any flags. The flags will be automatically assigned
based on user input. Only one argument is needed to call a function if files and directories are named a like.

#### --file
A full path to a file. This flag will be derived if a argument is a valid
path to a file.

#### --derive
A name of a file without path and .sh extension. This flag will be derived if a file
exists. The file must have a .sh extension.
