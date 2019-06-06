# Installation
```
wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
```
Or
```
git clone git@github.com:nicobrinkkemper/gabr.sh.git 
```


# What is gabr.sh
gabr.sh is a script to create a command-line program. The names of your directories, files and functions will dictate the api to interact with your program. To call a function with gabr.sh, just type in what you see. Let's illustrate that with a helloworld example.

## Hello world

```shell
$ echo "\
function helloworld() {
  echo hello world
}" > ./helloworld.sh
```
```shell
$ source ./gabr.sh
```
```shell
$ gabr helloworld
hello world
```
```shell
$ rm -rf ./helloworld ./gabr.sh
$ unset gabr
```
> Fore more examples, see ./example

## Why use Gabr.sh?

 - **Minimal API to reach your functions**
    Gabr's purpose is to call functions in files. You give it arguments and it
    tries really hard to turn that argument in to a function call. If it can do so,
    it will promtly run that function with the remaining arguments. After that,
    Gabr cleans up after itself and is ready to take on new requests.

 - **Strict mode**

    Functions you call with gabr.sh will run with `set -euo pipefail`. This will stop execution 
    at the slightest hick-up to prevent bugs from slipping in. Nonetheless, it will run
    cleanup code after it has crashed, making sure the next time you call your function
    it is resourced and also that the strict-mode does not stay in effect.

  - **Run globally without global pollution**

    - Only `gabr` will remain in global namespace.
    - `gabr` does not enter a subshell to run a function
      - To enter a subshell, use `function()(  )`
    - Adds `trap "${onCleanUp}" ERR SIGINT` to any function it runs, which enforces
      clean-up 

  - **Function nesting**

    `FUNCNEST` will be set to 50. Which will restrict recursion. A recursive bash function can crash a machine if not handled correctly. Making mistakes like that with won't be a issue
    if you always call that function with `gabr` during development.

  - **No global shell polution**
  
    Only the `gabr` function and two global variables (`GABR_ROOT`, `GABR_ENV`) will remain in the shell scope after a function is ran.

# "Functional" Bash Scripts
Gabr.sh allows you to write functional code. If you have a command that you need to
type in a lot, it's a good candidate to put in to a Bash function.

## Drawbacks
Bash isn't a functional language.  Calling functions has a cascading effect. If you call a function within a function, the caller will inherent the functions of the
called function. Let's illustrate that with a example:
```
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
hard to keep your functions pure. You can mitigate this in two ways: subshells, and unset -f. Gabr.sh chooses the latter, but this doesn't prevent you from writing subshell functions, like so `function fn() ( return; )`.


This is true because source is a function. When you source a file, you call a
function. Gabr facilitates this because it makes it really easy to call files
as if they were functions. 

## Keeping the names the same

By keeping the names the same, the api to request your functions can stay minimal.
Consider the following test:

```

```
