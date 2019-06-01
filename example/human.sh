function human(){ # -- e.g. gabr example human
  echo "That's me" >&2
  function sayhi(){
    if [[ $(type -t laugh) = function ]]; then
      echo Hello >&2
      function laugh(){
        echo "(˵ ͡° ͜ʖ ͡°˵)"
      }
    else
      echo Hi >&2
      function laugh(){
        echo Haha, yes >&2
        function laugh(){
          echo Hahaha, you\'re killing me >&2
        }
      }
    fi
  }
        # That's me
  sayhi # Hi
  laugh # Haha, yes
  laugh # Hahaha, you're killing me
  sayhi # Hello
  laugh # (˵ ͡° ͜ʖ ͡°˵)
}