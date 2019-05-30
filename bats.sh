#!/usr/bin/env bash


if [[ -f ./package.json ]]; then
    function install() { # -- e.g. gabr bats install
        npm install --save-dev bats
    }
else
    echo './package.json not found. Please run npm init' 1>&2
    return 1
fi

if [[ -f ./node_modules/.bin/bats ]]; then
    function test(){ # -- e.g. gabr bats test
        ./node_modules/.bin/bats ./${1:-gabr}.bats
    }
else
    echo './node_modules/.bin/bats not found. Please install bats.' 1>&2
    return 1
fi