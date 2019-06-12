# Gabr.sh

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
Gabr.sh allows you to write functional code. If you have a command that you need to
type in a lot, it's a good candidate to put in to a Bash function. Gabr makes it easy to
run that function, without adding anything to the file. Not having the procedural code to run the
function inside your files opens up neat code patterns with Bash.

## Usage
```
gabr [--file] [--derive] <directory | file | function> <arguments>
```
### Variables
Certain variable names alter the behavior of `gabr.sh`. `gabr` prefers inheriting variables, but will
create a local declaration otherwise.

[**GABR_ENV** | **env**]
Alters the output and behavior of the script.

  - dev | unset
    - `set -Euo pipefail` at subshell level
    - > Will stop at first hick-up
    - > Won't exit a shell during development
  - debug
    - `debug=(fn args dir filename)` at shell level
    - `set -Euo pipefail` at subshell level
    - > Will provide information about internal workings
  - prod
    - `set -euo pipefail` at shell level
    > The prod behavior is useful when you want the complete shell to exit on any hick-up.
  - any other value
    - Opt-out of above behavior
    > Opting-out is useful when you want to catch errors a different way


[**GABR_ROOT** | **root**]
Alters the directory which to look for functions as last resort
 - unset
    - Will `cd` to original $PWD
 - any other value
    - Will `cd` to this value when no functions are found at current directory
    > This is useful when you want to have a fixed root directory for utilities.

[**GABR_DEFAULT** | **default**]
Alters the function that called as last resort. A default variable and function will be
generated under this name if either of those don't exist. This generated function
 will just print a variable with the same name. (variable expansion)
> This means you can just assign a string to 'usage', and it will be printed if a function isn't found. Alternatively, a function called usage will give more control over the output.

- usage | unset
    - Will call a function called `usage`.
 - any other value
    - Will call a function under that name
    > Changing during source enables linking `usage` to a different function

[**dir** ]
Alters the directory that the function is called in.
 - unset
    - Will `cd` to the files location before calling it's function
    > Functions may be directory agnostic
 - any other value
    - Will `cd` to this value before calling the function
    > Changing during source enables setting a target directory for a file's functions

[**debug** ]
Alters the variables that will be debugged each cycle.
 - unset
    - When `env` is not `debug`, will debug nothing
    - When `env` is `debug`, will debug `fn`, `args`, `dir` and `filename`
 - any other value
    - Will `cd` to this value before calling the function
    > Changing during source enables setting a target directory for a file's functions

### Flags

Gabr does not require any flags. The flags will be automatically assigned
based on user input. Only one argument is needed to call a function if files
and directories are named a like.

#### --file
A full path to a file. This flag will be derived if a argument is a valid
path to a file.

#### --derive
A name of a file without path and .sh extension. This flag will be derived if a file
exists. The file must have a .sh extension.


## Why use Gabr.sh?

### Developer friendly
Use gabr if you like writing the least amount of Bash code. If you have a lot of one-off
tasks that you'd like to remember, put it in a function and let gabr.sh call it.

### Minimal API to reach your functions
Gabr's purpose is to call functions in files. You give it arguments and it
tries really hard to turn that argument in to a function call. If the names are the
same, you only have to type it once.

### Function nesting
`gabr` allows to loop back to itself. `FUNCNEST` is set to 50, as to not worry about recursion problems.

### "Functional" Bash Scripts
Gabr.sh allows you to write functional code. If you have a command that you need to
type in a lot, it's a good candidate to put in to a Bash function. Gabr makes it easy to
run that function, without adding anything to the file. Not having the procedural code to run the
function inside your files opens up interesting and clean code patterns with Bash.

# "functional" Bash
Bash isn't a functional language.  Calling functions has a cascading effect. If you call a function within a function, the caller will inherent the functions of the
called function. Let's illustrate that with a example:

```shell
function human(){
  echo "That's me" >&2
  function sayhi(){
    echo Hi >&2
    function laugh(){
      echo Haha, yes >&2
      function laugh(){
        echo Hahaha, you\'re killing me >&2
      }
    }
  }
}
human # That's me
sayhi # Hi
laugh # Haha, yes
laugh # Hahaha, you're killing me
sayhi # Hi
laugh # Haha, yes
```
> You can paste the code in your Bash terminal to see it in action

Like with CSS, the cascading effect can be problematic. It makes it very nuanced and
hard to keep your functions pure. You can mitigate this in two ways: subshells, and `unset -f`. Gabr.sh chooses the latter, but this doesn't prevent you from writing subshell functions, like so `function fn() ( return; )`.
