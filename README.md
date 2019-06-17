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

### GABR_ENV
`GABR_ENV` can be used to influence `IFS`, `set` builtin and `trap`s.
By default, it runs very strict. This is a good practice because it minimizes bugs.

```shell
$ export GABR_ENV=dev
```
> Will exit `gabr`'s subshell on errors. (`set -eEuo pipefail`) This is the default behavior.
>
> With this setting, `gabr` will not exit (crash) it's own shell on errors. The exitcode
> will be available as `$?`

```shell
$ export GABR_ENV=debug
```
> Same as `dev`, but will enter debug-mode. (`set -x`)

```shell
$ export GABR_ENV=prod
```
> Same as `dev`, but `set -eEuo pipefail` will be set in main shell instead.
>
> With this setting, `gabr` will exit (crash) it's own shell on errors. This means that
a terminal could close on errors.

```shell
$ export GABR_ENV=none
```
> Any other value than `dev`, `prod`, or `debug` opts-out of above rules.
> This also opts-out of setting a ERR SIGINT `trap` and setting `IFS`

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
> See the [Functions](#Functions)

### IFS
`gabr` defines `IFS` insides it's subshell.
By default it's set to newlines and tabs. (`local IFS=$'\n\t'`)
Functions called with `gabr` will share this `IFS` value.
This is a good practice, because it allows for arguments with spaces in it.
To disable this behavior use `export GABR_ENV=none`

## Buildtins
### Set 
`gabr` uses `set -eEuo pipefail`. The [manual](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html) gives more detailed information,
but it boils down to this:
 - **-e** Exit immediately on errors
 - **-E** Inherit traps
 - **-u** Error on unset variables
 - **-o pipefail** the return value is that of the last error

If `GABR_ENV` is not `dev`, `debug` or `prod`, `gabr` will opt-out of this behavior.

### Trap 
Gabr defines one trap to unsure that a function really fails early on errors. (`trap '(exit $?); return $?' ERR SIGINT`) This makes failing early on errors consistent. It also allows to exit any process with `ctrl+c`

If `GABR_ENV` is not `dev`, `debug` or `prod`, `gabr` will opt-out of this behavior.

### Local variables
Gabr defines the following local variables. These will be available in files sourced by Gabr. Variables that already exist will be inherited.

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

## Functions

### function usage ()
By default, this function will be called as a last-resort:
```bash
function usage() {
    echo $usage >&2
}
```
> Feel free to overwrite this function and/or variable

### function $default ()

The namespace for `usage` may be altered with `GABR_DEFAULT` or simply `default`. If `default` is not set to `usage`, `gabr` generates a function and variable for this name. If a function or variable already exist with this name, these will be used instead. The generated function looks like this:

```bash
function $default() {
    echo ${!default} >&2
}
```
> The `!` introduces variable indirection. [Read more](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)

## Flags

Gabr does not require any flags. Gabr stops on any argument that starts with a dash (-).