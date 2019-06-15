
## Debug Example
This example assumes you have the gabr function sourced.
```shell
$ function debug(){
  declare -p $@
}
```
> Write a simple function

```shell
$ gabr debug BASH_VERSION BASH_SOURCE
# declare -- BASH_VERSION="4.4.19(1)-release"
# declare -a BASH_SOURCE=([0]="main" [1]="/home/usr/.nvm/versions/node/v11.7.0/bin/gabr.linux")
```
> Right. It called that function on the spot

```shell
$ declare -f debug > ./debug.sh
$ unset -f debug
```
> Put the function in a file and unset it

```shell
$ gabr debug BASH_SOURCE
# declare -a BASH_SOURCE=([0]="./debug.sh" [1]="/home/usr/.nvm/versions/node/v11.7.0/bin/gabr.linux")
```
> Right, it still called it. Now let's debug something.

```shell
$ echo "\
debug=(args)
function badarray() {
    mapfile foo < <(true; echo foo)
    echo \${foo[-1]:-} >&2 # foo
    mapfile foo < <(false; echo foo)
    echo \${foo[-1]:-} >&2
}
" > ./debug.sh
```
> This would be a nasty case to debug 

```shell
$ gabr debug badarray
# args=([0]="badarray")
# -----------
# Calling badarray
foo
./debug.sh: line 6: foo: bad array subscript
```
> Fair enough. Gabr debugged it by not debugging it.
> For more examples crash, checkout the example directory.
