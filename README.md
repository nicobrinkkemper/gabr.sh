# gabr.sh
Make your bash functions accessible with one script. Any function in any file can be reached through a simple api that is solely based on the names of your files, directories and functions.

# Installation 
```
wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
```

# Hello world
```
source ./gabr.sh
echo "\
function helloworld() {
 echo hello world >&2
}
" > ./helloworld.sh
gabr helloworld
# remove it
rm ./helloworld.sh
```

# Strictmode
Functions you call with gabr.sh will run in strictmode. If you use gabr you don't have to
put this in every file.
```
declare IFS=$'\n\t'
set -euo pipefail
```
If you want to learn more about this, I suggest reading:
 - [Use the Unofficial Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)

## Why use Gabr.sh?
Gabr's purpose is to call functions in files. You give it arguments and it
tries really hard to turn that argument in to a function call. If it can do so,
it will promtly run that function with the remaining arguments. After that,
Gabr cleans up after itself.

## "Functional" Bash Scripts
Bash isn't a functional language. The way functions work in Bash
is more akin to CSS. Calling functions has a cascading effect. If you call a
function within a function, the caller will inherent the functions of the
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
```

Like CSS, the cascading effect can present many problems. It makes it very nuanced and therefor
hard to keep your functions pure. You can mitigate this by seeing the file as a function. This is true
because source is a function. Therefor, when you source a file, you call a function. Gabr facilitates in this
because it clearly separates scoping from function calling. Gabr scopes files
