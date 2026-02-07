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
Gabr is a Bash-function designed to call other Bash-functions.
Gabr takes arguments and will try to turn that in to a function call.
Gabr takes the path of least resistance towards a function call.
Let's illustrate that with a flowchart.

![Happy Flowchart](https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/Gabr.sh.svg?sanitize=true)

> This flowchart doesn't show error cases. These cases are mostly when the last argument did not result
> in the execution of a real function.

Let's illustrate further with a code example. 
```shell
$ echo "\
if [ \$# -eq 0 ]; then
  printf '%s\n' 'Usage: gabr hello world' >&2
fi
function world() {
  printf '%s\n' 'Hello World.' >&2
}
" > ./hello.sh
$ gabr hello
Usage: gabr hello world
$ gabr hello world
Hello World.
```

And there you have it. That's all it does. But it is deceptively useful.

## Why use gabr.sh?
Use it when you want to make a simple API to automate stuff *you* care about.
Consider the following commands to delete a tag with git:
```shell
git tag -d 1.0.1
git push origin :refs/tags/1.0.1
```
This is hard to remember next time you'd need it.
It's also hard to delete multiple tags because you'd need
to shift your cursor around to change the tags.
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
will be available through a simple api that is easy to communicate.
Just type in what you see.

## Sourcing `gabr` vs running `gabr`
For normal use I recommend running `gabr` as a file. This is default behavior when running `npm link`.
If you've forked the repo and npm-linked from there then any changes will update the linked file.

It is also possible to source `gabr`. This can be used in scripts or a shell-terminal.
By running `. gabr`, gabr will not run as a file but instead as a function. For example:
```shell
$ . gabr
$ GABR_DEBUG_MODE=1 # we do not need to export this
$ gabr example human
``` 

## Variables

### GABR_STRICT_MODE (default:true)
A variable called `GABR_STRICT_MODE` may be used to toggle the following snippet:
```bash
set -eEuo pipefail
local IFS=$'\n\t'
trap 'return $?' ERR SIGINT
```
This snippet will run once inside the function's subshell clause.
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

### GABR_DEBUG_MODE
Setting this variable to a value will turn on debug mode for files and functions.
The `gabr` function will do `set -x` before and `set +x` after every
file source and function call.
```shell
$ export GABR_DEBUG_MODE=true
```

This variable is useful, because just using `set -x` might also output `gabr`'s internal code.

### GABR_ROOT
If `GABR_ROOT` is set to a value the `gabr` function will change directory
to this value on every invocation.
```shell
$ export GABR_ROOT=$(git rev-parse --show-toplevel)
```
> This will make files at the root of a git repository accessible to the `gabr` function

This variable is powerful, it will make arguments put in more likely to result
in the same output. Keep in mind that the `gabr` function will lose it's flexibility,
it will always run from a fixed location.

### GABR_DEFAULT
A global variable called `GABR_DEFAULT` may be used to influence the exit condition.
`gabr` will exit it's internal loop when it finds a function it can call.
The argument `usage` always results in a function call and thus can be used as a means to exit.
A second option may be added by setting `GABR_DEFAULT` (global) or `default` (local) to a value.

```shell
$ export GABR_DEFAULT=index
```
> This will make `index.sh` behave similar to index-files in other programming languages.
> But `usage` makes more sense for Bash IMO

### GABR_EXT
`GABR_EXT` may be used to alter the value of `ext`. The default value is `.sh`.
Files with this extension are sourced, files without are ran with `exec`.

```shell
$ export GABR_EXT=.bash
```

With the right shebang, any programming language can be called. However, keep in mind
that `gabr` also looks for files without an extension. These files will always run with
`exec`.

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
A default function will be generated that prints usage information about `gabr` when:

- No argument are given
- The argument is `usage`
- The argument is the value of `GABR_DEFAULT` and `GABR_DEFAULT` is set

### function usage ()
By default `usage` is an important namespace for the `gabr` function. `usage` behaves
like an exit condition. The argument will always result in a function call, and thus
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

Finally, a default file may be consulted. This is applicable when the
argument is only a directory. For an example of this, see `./test/usage.sh`
or run `gabr test` to see it in action.

### function $default ()
The name of the `usage` function may be altered with `GABR_DEFAULT` or simply `default`.
A last-resort function and variable will be made for this name instead.
The usage namespace will keep functioning.
This is done through variable indirection. ([reference](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html))
To generate a function with a dynamic name a small eval trick is used.

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
