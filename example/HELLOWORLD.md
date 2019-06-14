Fore more examples, see the example directory.

# Hello world
```shell
$ wget https://raw.githubusercontent.com/nicobrinkkemper/gabr.sh/master/gabr.sh
$ source ./gabr.sh
```
```shell
$ echo "\
function helloworld() {
  echo hello world
}" > ./helloworld.sh
```
```shell
$ gabr helloworld
hello world
```

## With directory
```shell
$ mkdir hello
```
```shell
$ echo "\
function world() {
  echo hello world
}" > ./hello/world.sh
```
```shell
$ gabr hello world
hello world
```

## With recursion
```shell
$ echo "\
function hello() {
    echo hello
    gabr
}

if ! [[ \$(type -t world) = function ]]; then
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

## Cleanup
```shell
rm -rf hello
rm -f helloworld.sh
```
