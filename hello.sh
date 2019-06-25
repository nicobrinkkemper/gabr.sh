function usage() {
  printf '%s\n' 'Usage: gabr hello world'
}
function world() {
  printf '%s\n' 'Hello World.' >&2
}

