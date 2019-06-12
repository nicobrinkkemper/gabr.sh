

function hello() {
    echo hello
    gabr
}

if ! [[ $(type -t world) = function ]]; then
  function world() {
    echo world
    unset -f world
    gabr world
  }
fi