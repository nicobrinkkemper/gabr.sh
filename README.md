# Installation
```
wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
```
Or
```
npm install gabr.sh
npm link
```


# What is gabr.sh
Gabr.sh allows you to write functional code. If you have a command that you need to
type in a lot, it's a good candidate to put in to a Bash function. Gabr makes it easy to
run that function, without adding anything to the file. Not having the procedural code to run the
function inside your files opens up interesting and clean code patterns with Bash.

## Hello world

```shell
$ mkdir helloworld
$ echo "\
function helloworld() {
  echo hello world
}" > ./helloworld/helloworld.sh
```
```shell
$ source ./gabr.sh
```
```shell
$ gabr helloworld
hello world
```
> Fore more examples, see ./example

## Why use Gabr.sh?

### Developer friendly
Use gabr if you like writing the least amount of Bash code. If you have a lot of one-off
tasks that you'd like to remember, put it in a function and let gabr.sh call it.

### Minimal API to reach your functions
Gabr's purpose is to call functions in files. You give it arguments and it
tries really hard to turn that argument in to a function call. If the names are the
same, you only have to type it once.

### Strict mode
Functions you call with `gabr.sh` will run with `set -euo pipefail`. This will stop execution 
at the slightest hick-up to prevent bugs from slipping in. Nonetheless, it will run
cleanup code on completion and prevent actual terminal exit when `GABR_ENV` is not `prod`.

```shell
$ echo "\
function owo() {
  OwO
  # This wil not be ran
  echo "I made a oopsy" >&2 
}" > ./owo.sh

$ gabr owo
OwO: command not found
Exitcode 127 prevented, returned 0 instead
```

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
