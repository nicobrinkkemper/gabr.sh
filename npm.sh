function release() {
    git add .
    git commit -m ${1:-"New release will bump ${version:-}"}
    npm test && npm run release
}

if ! [[ -v version ]] && [[ $(which node) ]]; then
    declare version=$(node -p -e "require('./package.json').version")
fi