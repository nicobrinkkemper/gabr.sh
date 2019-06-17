# Gabr.sh
[![npm package](https://img.shields.io/npm/v/gabr.sh.svg)](https://www.npmjs.com/package/gabr.sh)
[![Continuous integration status for Linux and macOS](https://travis-ci.org/nicobrinkkemper/gabr.sh.svg?branch=master&label=travis%20build)](https://travis-ci.org/bats-core/bats-core)
## Installation
```shell
$ wget git@github.com:nicobrinkkemper/gabr.sh.git
$ source ./gabr.sh
```
> 

### Install as node_module
```shell
$ npm install --save-dev gabr.sh
$ npm link
```
> When installed like this, `gabr` will run as a file.
> If you want to run `gabr` as a local function, try `source $(which gabr)`

## What is gabr.sh
Gabr is a Bash function designed to call other Bash functions.
Gabr takes arguments and will try to turn that in to a function call.
Gabr takes the path of least resistance towards a function call.
Let's illustrate that with a flowchart.

![Alt text](./Gabr.sh.svg)


## Variables
### IFS
`gabr` defines `IFS` insides it's subshell. It's set to newlines and tabs. Functions
called with `gabr` will share this `IFS` value.
```
local IFS=$'\n\t'
```
> This is a good practice, because it allows for arguments with spaces in it

### GABR_ENV
If defined, it can turn some opinionated features on or off.
```shell
$ export GABR_ENV=dev
```
> Will exit subshell on errors (non-zero return/unbound variables)
```shell
$ export GABR_ENV=debug
```
> `set -eExuo pipefail` at main level
```shell
$ export GABR_ENV=prod
```
> `set -eExuo pipefail` at main level
```shell
$ export GABR_ENV=none
```
> Any other value than `dev`, `prod`, or `debug` opts-out of above rules


### Set builtin
`gabr` uses `set -eEuo pipefail`. The [manual](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html) gives more detailed information,
but it boils down to this:
 - **-e** Exit immediately on errors
 - **-E** Inherit traps
 - **-u** Error on unset variables
 - **-o pipefail** the return value is that of the last error

But that is not all. **-E** gave the hint away maybe. Gabr defines one trap, and
it looks like this:

```
trap '(exit $?)' ERR SIGINT
```
The trap will ensure that a function really fails. However, `gabr` does not intend to catch errors. If `GABR_ENV` is not dev, debug or prod, will opt-out of this behavior.

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
Gabr defines the following variables. These will be available in files sourced by Gabr.
Variables that already exist will be inherited.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| env          	|       	| The strictness of the function           	| dev                                    	| May be set by `GABR_ENV`     	            |
| root         	|       	| The fallback directory                   	| $PWD                                   	| May be set by `GABR_ROOT`    	            |
| default      	|       	| Name of fallback function                	| usage                                  	| May be set by `GABR_ENV`              	|
| $default     	|       	| String printed by fallback function      	| $usage                                   	| See [Usage](#Usage)                     	|
| usage        	| -A    	| Usage string                            	| "Usage: gabr [file] function..."         	|                                          	|
| fn           	|       	| The called function                      	| usage                                  	|                                         	|
| args         	| -a    	| The arguments for the function           	| ()                                     	| Also available as ${@}                    |
| file        	|       	| The sourced file                       	|                                         	|                                         	|
| dir          	|       	| The relative directory of the file     	| .                                      	| Wil be cd'd to before calling the function|
| ext          	|       	| The extension to use       	            | .sh                                      	| Gabr also looks for files without extension|
| fullCommand  	|       	| The full initial command as string        | gabr ${@}                               	| Handy for custom `usage` implementations. See `./example/usage.md` |

## Flags

Gabr does not require any flags. Gabr stops on any argument that starts with a dash (-).

## Functions

### Usage
By default, this function will be called as a last-resort.
```shell
function usage() {
    echo $usage >&2
}
```
> Feel free to overwrite this function and/or variable

The namespace for `usage` may be altered with `GABR_DEFAULT` or simply `default`. If `default` is not set to `usage`, `gabr` generates
a function and variable for this name. If a function or variable already exist with this name, they will be used instead.
```shell
source /dev/stdin << EOF
function $default() {
    echo '${!default}' >&2
}
EOF
```
> The `!` introduces variable indirection. [Read more](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)