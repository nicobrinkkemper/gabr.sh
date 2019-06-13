function release() { # [ message ] - Release with a message
    git add . || 'Nothing to add'
    git commit -m ${1:-"New release will bump ${version:-}"} || 'Nothing to commit'
    npm test;
    npm run release;
}

function deprecate() {
    local version=${1:-'2.0.0'}
    npm deprecate gabr.sh@${version} ${2:-"${version} is no longer supported"}
}

if ! [[ -v version ]] && [[ $(which node) ]]; then
    declare version=$(node -p -e "require('./package.json').version")
fi