#!/usr/bin/env bash
if ! command -v git >/dev/null; then
    echo "Warning: git is not available" 1>&2
    return 1
fi
if ! command -v node >/dev/null; then
    echo "Warning: node is not available" 1>&2
    return 1
fi
declare npmRoot="$(git rev-parse --show-toplevel)"
declare -a data=(
    $(node -p -e "\
const data=require('${npmRoot}/package.json');
[
    data.name,
    data.version
].join('\n')
") 
)
declare name=${data[0]}
declare version=${data[1]}
function release() { # [ message ] - Release with a message
    cd $npmRoot
    git add . || 'Nothing to add'
    git commit -m ${1:-"New release will bump ${version:-}"} || 'Nothing to commit'
    git push
    npm test;
    npm run release;
}

function deprecate() { # [version] -- deprecate a version
    cd $npmRoot
    if [[ $# -eq 0 ]]; then
        echo "\
Usage: deprecate [version] [message] -- e.g. deprecate 0.0.2 \"This version is too old\"
    -- \$1 string   version number          (default:current)
    -- \$2 string   reason of deprecation   (default:'x.x.x is no longer supported')"
        return
    fi
    local version="${1:-${version}}"
    shift
    local reason="${@}"
    npm deprecate ${name}@${version} ${reason:-"${version} is no longer supported"}
}