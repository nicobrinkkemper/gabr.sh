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
$ git clone https://github.com/nicobrinkkemper/gabr.sh.git gabr
$ cd gabr
$ npm link
```

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

![Happy Flowchart](https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/Gabr.sh.svg)

> This flowchart doesn't show error cases. These cases are mostly when the last argument did not result
> in the execution of a real function.

Let's illustrate further with a code example. 
```shell
$ echo "\
function hello() {
  printf '%s\n' 'Usage: gabr hello world' >&2
}
function world() {
  printf '%s\n' 'Hello World.' >&2
}
" > ./hello.sh
$ gabr hello
Usage: gabr hello world
$ gabr hello world
Hello World.
```
> By naming the file and the function hello,
> a tiny API emerged to call the function.

A different approach would be:
```shell
$ echo "\
function usage() {
  printf '%s\n' 'Usage: gabr hello world'
}
function world() {
  printf '%s\n' 'Hello World.' >&2
}
" > ./hello.sh
$ gabr hello
Usage: gabr hello world
$ gabr hello usage
Usage: gabr hello world
$ gabr hello world
Hello World.
```
> See [functions](#Functions) for a different variation of this

## Why use gabr.sh?
Use it when you want to write a lot of Bash functions.
Consider the following commands to delete a tag with git:
```shell
git tag -d 1.0.1
git push origin :refs/tags/1.0.1
```
This is hard to remember next time you'd need it.
Or say you have a lot of tags to delete.
Now consider the following function.
```bash
set -eu
function deleteTag() {
    git tag -d \$1
    git push origin :refs/tags/\$1
}
```
> Let's say it's saved in `./git.sh`

This is easy to forget too, but one can refresh memory by looking at the file.

To run this function like `gabr` would, one could simply write:
```shell
$ (. git.sh; deleteTag 1.0.1)
```
But doing it like this is hard to communicate and prone to human error.
With `gabr` a more direct api emerges to do these kind of things:
```
$ gabr git deleteTag 1.0.1
```
With this basic concept, all functions you see in .sh files
will be available through a simple api that is shareable.


## Variables

### Variables
### GABR_STRICT_MODE (default:true)
A variable called `GABR_STRICT_MODE` may be used to toggle the following snippet:
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
    If `return` is executed by a `trap ERR` handler, the last command used to determine the non-zero status is the last command executed before the trap handler. `trap 'return $?' ERR` will ensure the conditions obeyed by the errexit (-e) option for older Bash versions. Furthermore, `SIGINT` will be handled the same way, which allows a user to interrupt (ctrl+C) any long running script. ([reference](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html))

To opt-out of strict-mode:
```shell
$ export GABR_STRICT_MODE=off
```
> export is not needed when running as a local function

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
> This will make `index.sh` behave similar to index-files in other programming languages

This variable is useful, but the default value `usage` is probably the way to go. 

### GABR_EXT
`GABR_EXT` may be used to alter the value of `ext`. Files with a `.sh` extension are
sourced, files without are ran with `exec`

```shell
$ export GABR_EXT=.bash
```

With the right shebang, any programming language can be called. However, keep in mind
that `gabr` also looks for files without a extension. These files will always run with
`exec`. For example, see `./example/javascript`
```shell
$ gabr example javascript hello
Arguments received: 3
0 -> .../node/v11.7.0/bin/node
1 -> .../gabr/example/javascript
2 -> hello
```

### Local variables
Gabr defines the following local variables. These will be defined in sourced files.

| variable     	| type  	| description                              	| default                                	| Note                                    	|
|--------------	|-------	|------------------------------------------	|----------------------------------------	|-----------------------------------------	|
| default      	|       	| Name of fallback namespace              	| usage                                  	| May be set by `GABR_DEFAULT`            	|
| usage        	|       	| Usage string                            	| "Usage: gabr [file] function..."         	|                                          	|
| $default     	|       	| String printed by fallback function      	| $usage                                   	| See [Functions](#Functions)              	|
| fn           	|       	| The called function                      	|                                     	    |                                     	    |
| args         	| -a    	| The left-over arguments                   | ()                                     	| Available as ${@} in sourced files/functions|
| prevArgs      | -a    	| The successful arguments                  | ()                                     	|                                           |
| file        	|       	| The sourced file                       	|                                         	| Will be set to the latest sourced file    |
| dir          	|       	| The directory of the file     	        | .                                      	| Will be relative path from starting point |
| ext          	|       	| Extension to use `source`                 | .sh                                       | `exec` is used for files without extension|
| FUNCNEST     	|       	| See manual ([reference](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)) | 50 | Prohibits overly recursive function calls |

## Functions
### function usage ()
By default `usage` is a important namespace for the `gabr` function. `usage` behaves
like a exit condition. The argument will always result in a function call, and thus
exit the interal loop. The following snippet shows the last-resort function that will be generated when a `usage` function or file is not available.

```bash
# ...on invocation
local usage="gabr [directory | file] function [arguments] -- A function to call other functions."
# ...later, if all else fails
function usage() {
    echo $usage >&2
}
```

The `usage` variable may be altered during file source.
Below snippet will force `usage` when the last argument was a file name but not a function name.

```bash
if [ $# -eq 0 ]; then
    usage='help-info-for-this-file'
    set -- usage
fi
```

This can be useful for filenames that may not contain a function with that name.
A alternative approach would be to just define the `usage` function.
It will be called if no arguments are given after the file argument.

```bash
usage(){
    echo "npm test" >&2
    npm test
}
```

Finally, a default file may be consulted when the
a argument is a directory but not a file. For a example of this, see `./test/usage.sh`
or run `gabr test` to see it in action.

### function $default ()
The namespace for `usage` may be altered with `GABR_DEFAULT` or simply `default`.
A last-resort function and variable will be made for this name instead.
This is done through variable indirection. ([reference](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html))
To generate a function with a dynamic name a small eval trick is used. For this reason
the `default` variable may not contain special-characters.

```bash
default=help
help(){
    printf "help-info-for-this-file"
}
```
> This will run the `help` function when no arguments come after a file argument

## Flags

The internal loop wil error at any argument that starts with a dash (-).
Any argument that comes behind the dash will be printed as
a warning to the user. The return code will be 1.
```bash
set -- '-' 'Error, something went wrong'
```
