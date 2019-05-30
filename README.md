# gabr.sh
Make your bash functions accessible with one script. Any function in any file can be reached through a simple api that is solely based on 
the names of your files and functions.


# Installation 

```
wget https://raw.githubusercontent.com/raspberrypi/linux/rpi-4.9.y/arch/arm/configs/bcmrpi_defconfig
```

# Strictmode
Functions you call with gabr.sh will run in strictmode. If you use gabr you don't have to
put this in every file.
```
set -euo pipefail
```
If you want to learn more about this, I suggest reading:
 - [Use the Unofficial Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)

## Why use Gabr.sh?
Gabr's purpose is to call functions in files. You give it arguments and it
tries really hard to turn that argument in to a function call. If it can do so,
it will promtly run that function with the remaining arguments. After that,
Gabr cleans up after itself.

## Why functions?
Bash isn't a functional language. The way functions work in Bash
is more akin to CSS. Calling functions has a cascading effect. If you call a
function within a function, the caller will inherent the functions of the
called function. Let's illustrate this with a example:
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
> You can paste the code in your bash terminal to see it in action
```

Like CSS, the cascading effect can present many problems. It makes it very nuanced and therefor
hard to keep your functions pure.
