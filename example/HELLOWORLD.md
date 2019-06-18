

## With directory
```shell
$ mkdir hello
```
> Make a directory `hello`

```shell
$ echo "\
function world() {
  echo hello world
}" > ./hello/world.sh
```
> Put `world.sh` in the directory

```shell
$ gabr hello world
hello world
```
> First argument changes `dir` to `./hello`, second argument sources the file and calls the function

## With recursion
```shell
$ echo "\
function hello() {
    echo hello
    gabr
}

if ! [ \"\$(type -t world)\" = 'function' ]; then
  function world() {
    echo world
    unset -f world
    gabr world
  }
fi" > ./hello/hello.sh
```
```shell
$ gabr hello world
hello
world
hello world
```
> First argument changes `dir` to `./hello` sources the file and calls `hello`.
> Which sets of a chain of events leading back to `world.sh`

## Cleanup
```shell
rm -rf hello
rm -f helloworld.sh
```
