function release() { # [ message ] - Release with a message
    git add . || 'Nothing to add'
    git commit -m ${1:-"New release will bump ${version:-}"} || 'Nothing to commit'
    npm test;
    npm run release;
}

function deprecate() { # [version] -- deprecate a version
    if [[ $# -eq 0 ]]; then
        echo "\
Usage: deprecate [version] [message] -- e.g. deprecate 0.0.2 no long need it
    -- \$1 string   version number          (default:current)     
    -- \$2 string   reason of deprecation   (default:'x.x.x is no longer supported')"
        return
    fi
    local version="${1:-${version}}"
    shift
    local reason="${@}"
    npm deprecate ${name}@${version} ${reason:-"${version} is no longer supported"}
}

if ! [[ $(which node) ]]; then
    echo "Warning: node is not available" 1>&2
fi
if ! [[ -v version ]]; then
    declare version=$(node -p -e "require('../package.json').version")
fi
if ! [[ -v name ]]; then
    declare name=$(node -p -e "require('../package.json').name")
fi