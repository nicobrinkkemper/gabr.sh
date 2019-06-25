function usage() {
  printf '%s' 'Usage: gabr hello world'
}
function world() {
  printf '%s\n' 'Hello World.' >&2
}

