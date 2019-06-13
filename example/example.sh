#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
    set -- usage
fi
declare usageFilename=${filename:-'example'}

function _usageFunctions(){
    local usageScope=$(
        echo "${stack}" "${stack}" "$(declare -F)" |
            tr ' ' '\n' |
            sort        |
            uniq -u     |
            awk '! /^_/{print $0}' | # hide underscore prefixed
            tr '\n' "|"
    );
    if [[ -v usageScope ]] && [[ ${#usageScope} -gt 1 ]]; then
        echo " [${usageScope:0: -1}]"
    fi
}

function _usageFiles(){
    local usageFiles=$(
    find . -maxdepth 1 ! -name "${usageFilename}.sh" ! -name "${filename}.sh" -name '*.sh' |
        cut -c3- | 
        rev      | 
        cut -c4- | 
        rev      |
        awk '!/^\./{ print $0 }' | # hide dot prefixed
        tr '\n' "|"
    );
    if [[ -v usageFiles ]] && [[ ${#usageFiles} -gt 1 ]]; then
        echo " [${usageFiles:0: -1}]"
    fi
}

function usage(){
    echo "Usage: gabr \
$( [[ ${filename} = $usageFilename ]] && echo ${filename} || echo "$usageFilename $filename" )\
$(_usageFiles)\
$(_usageFunctions)\
 -- e.g. gabr $usageFilename crash" >&2
}