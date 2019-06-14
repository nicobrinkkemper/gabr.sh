function return1(){
    exitcode=1
    return 1
}

function debug(){
    echo failed-status-${GABR_ENV:-dev}="\"${status}\"" 1>&2
    echo BASH_VERSION="\"${BASH_VERSION}\"" 1>&2
}

function gabrLocation(){
    if ! [ -f "./gabr.sh" ]; then
        echo PWD=$PWD >&2
        echo "Can't find gabr.sh" >&2
        return 1
    fi
    echo "./gabr.sh"
}

@test "Gabr returns non error code" {
    source $(gabrLocation)
    run gabr
    debug
    [ $status -eq 0 ]
}

@test "Gabr errors the same return code" {
    source $(gabrLocation)
    mkdir -p boo
    echo "\
function boo(){
    echo boo >&2
    return 123
}
" > boo/boo.sh
    GABR_ENV=dev
    run gabr boo
    debug
    [ "$status" -gt 0 ]
    GABR_ENV=debug
    run gabr boo
    debug
    [ "$status" -gt 0 ]
    GABR_ENV=prod
    run gabr boo
    debug
    [ "$status" -gt 0 ]
    trap 'rm -rf ./boo' RETURN
}

@test "Gabr global errors when a file exits" {
    source $(gabrLocation)
    mkdir -p spooky
    echo "\
return 1
" > spooky/spooky.sh
    GABR_ENV=dev
    run gabr spooky
    debug
    [ "$status" -eq 1 ]
    GABR_ENV=debug
    run gabr spooky
    debug
    [ "$status" -eq 1 ]
    GABR_ENV=prod
    run gabr spooky
    debug
    [ "$status" -eq 1 ]
    trap 'rm -rf ./spooky' RETURN
}

@test "gabr errors when a function is undefined" {
    source $(gabrLocation)
    GABR_ENV=dev
    run gabr undefined
    debug
    [ "$status" -eq 1 ]
    GABR_ENV=debug
    run gabr undefined
    debug
    [ "$status" -eq 1 ]
    GABR_ENV=prod
    run gabr undefined
    debug
    [ "$status" -eq 1 ]
}

@test "gabr errors when a function returns 1" {
    source $(gabrLocation)
    GABR_ENV=dev
    run gabr return1
    debug
    [ "$status" -eq 1 ]
    GABR_ENV=debug
    run gabr return1
    debug
    [ "$status" -eq 1 ]
    GABR_ENV=prod
    run gabr return1
    debug
    [ "$status" -eq 1 ]
}

@test "gabr crashes shell when env is prod" {
    source $(gabrLocation)
    GABR_ENV=dev
    result="$(echo $(gabr return1; echo "${GABR_ENV}_"))"
    GABR_ENV=debug
    result+="$(echo $(gabr return1; echo "${GABR_ENV}_"))"
    GABR_ENV=prod
    result+="$(echo $(gabr return1; echo "${GABR_ENV}_"))" # can not print due to crash of shell
    echo failed-result="\"${result}\"" 1>&2
    [ $result = "dev_debug_" ]
}

@test "gabr can change default functionality with GABR_DEFAULT / variable indirection" {
    source $(gabrLocation)
    GABR_ENV=dev
    debug=()
    local normalOutput=$(gabr 2>&1)
    echo failed-normalOutput="\"${normalOutput}\"" 1>&2
    [ -n "$normalOutput" ]
    GABR_DEFAULT=help
    local helpOutput=$(gabr 2>&1)
    echo failed-helpOutput="\"${helpOutput}\"" 1>&2
    [ "$helpOutput" = "$normalOutput" ]
    local help='some-string' # this will be used by variable indirection
    local helpStringOutput=$(gabr 2>&1)
    echo failed-helpStringOutput="\"${helpStringOutput}\"" 1>&2
    [ "$helpStringOutput" = "some-string" ]
    function help(){
        echo 'some-other-string'
    }
    local helpFunctionOutput=$(gabr 2>&1)
    echo failed-helpFunctionOutput="\"${helpFunctionOutput}\"" 1>&2
    [ "$helpFunctionOutput" = "some-other-string" ]
}

@test "gabr does not walk over a error" {
    function undefined(){
        iamnotdefined;
        declare -x iamnotdefined=iamnotdefined
        return $?
    }
    local exitcode=0 # needs to be set to a variable in order to inherit Gabr's exitcode\
    source $(gabrLocation)
    GABR_ENV=dev
    run gabr undefined;
    ! [ -v iamnotdefined ]
    GABR_ENV=debug
    run gabr undefined;
    ! [ -v iamnotdefined ]
    GABR_ENV=prod
    run gabr undefined;
    ! [ -v iamnotdefined ]
}

@test "Running and sourcing gabr only adds Gabr to scope" {
    function diffStack(){
        difference(){
            echo "${stack}" "${stack}" "$@" | tr ' ' '\n' | sort | uniq -u;
        }
        difference ${@} 
    }
    local herestack=$(declare -F -f)
    source $(gabrLocation)
    local -a result=($(
        gabr diffStack $(declare -F -f);
        echo -;
        gabr diffStack $(declare -F -f)
        echo -;
        echo "${herestack}" "${herestack}" "$(declare -F -f)" | tr ' ' '\n' | sort | uniq -u
    ))
    local str=$(IFS=$' '; echo ${result[*]})
    echo failed-result=$str 1>&2
    [ "$str" = "- - gabr" ]

}

@test "Gabr can find a file and run it's functions" {
    echo "\
function sayhi(){
    echo hi
}
function saybye(){
    echo bye
}" > ./sayhi.sh
    source $(gabrLocation)
    local result="$(gabr ./sayhi.sh sayhi) $(gabr ./sayhi.sh) $(gabr sayhi) $(gabr ./sayhi.sh saybye)"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./sayhi.sh' RETURN
    [ "$result"  = 'hi hi hi bye' ]
}

@test "Gabr does not alter spaces in arguments" {
    echo "\
function whatdidisay(){
    echo \"\${@}\"
}" > ./whatdidisay.sh
    source $(gabrLocation)
    local result="$(gabr whatdidisay ' jim ' " has long " " cheeks ")"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./whatdidisay.sh' RETURN
    [ "$result"  = ' jim   has long   cheeks ' ]
}

@test "Gabr sees tabs as separator" {
    echo "\
function spectabular(){
    echo \"\${@}\"
}" > ./spectabular.sh
    source $(gabrLocation)
    local result="$(gabr spectabular "$(echo -e '\t')<tabs>$(echo -e '\t')" "<ta$(echo -e '\t')bs>")"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./spectabular.sh' RETURN
    [ "$result"  = "<tabs> <ta bs>" ]
}


@test "Gabr has minimal api when file, directory and function named the same" {
    mkdir -p 'sophie'
    echo "\
function sophie(){
    echo Sophie
}" > sophie/sophie.sh
    source $(gabrLocation)
    local result="$(gabr sophie)"
    trap 'rm -rf sophie' RETURN
    [ "$result"  = "Sophie" ]
}

@test "Gabr runs in directory relative to file in which function is called" {
    mkdir -p 'whereru'
    echo "\
function whereru(){
    echo \${PWD}
}
" > whereru/whereru.sh
    source $(gabrLocation)
    local localPWD=$(pwd)
    local result="$(gabr whereru)"
    echo failed-result="\"${result[@]: -8}\"" 1>&2
    trap 'rm -rf whereru' RETURN
    [ "${result[@]: -8}"  = "/whereru" ]
}

@test "Gabr can cd to directories and run files" {
    mkdir -p '.jimtest'
    echo "\
function jim(){
    echo jim >&2
    echo .jimtest/willem.sh 
}" > .jimtest/jim.sh
echo "\
dir="\${dir:-.}/.jimtest"
function willem(){
    echo willem >&2
    gabr ./bonito.sh
}" > .jimtest/willem.sh
echo "\
function bonito(){
    echo bonito >&2
    echo \"de wever\"
}" > .jimtest/bonito.sh
    source $(gabrLocation)
    local result="$(gabr $(gabr .jimtest jim))"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -rf .jimtest' RETURN
    [ "$result"  = "de wever" ]
}
