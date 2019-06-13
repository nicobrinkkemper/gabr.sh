function return127(){
    exitcode=127
    return 127
}

function return1(){
    exitcode=1
    return 1
}

@test "Gabr returns non error code" {
    source ./gabr.sh
    run gabr
    echo failed-status="\"${status}\"" 1>&2
    [[ $status -eq 0 ]]
}

@test "Gabr errors the same return code" {
    source ./gabr.sh
    mkdir -p boo
    echo "\
function boo(){
    echo boo >&2
    return 123
}
" > boo/boo.sh
    GABR_ENV=dev
    run gabr boo
    echo failed-status-dev="\"${status}\"" 1>&2
    [[ "$status" -eq 123 ]]
    GABR_ENV=debug
    run gabr boo
    echo failed-status-debug="\"${status}\"" 1>&2
    [[ "$status" -eq 123 ]]
    GABR_ENV=prod
    run gabr boo
    echo failed-status-prod="\"${status}\"" 1>&2
    [[ "$status" -eq 123 ]]
    trap 'rm -rf ./boo' RETURN
}

@test "Gabr global errors when a file returns 127" {
    source ./gabr.sh
    mkdir -p spooky
    echo "\
spooky
" > spooky/spooky.sh
    GABR_ENV=dev
    run gabr spooky
    echo failed-status-dev="\"${status}\"" 1>&2
    [[ "$status" -eq 127 ]]
    GABR_ENV=debug
    run gabr spooky
    echo failed-status-debug="\"${status}\"" 1>&2
    [[ "$status" -eq 127 ]]
    GABR_ENV=prod
    run gabr spooky
    echo failed-status-prod="\"${status}\"" 1>&2
    [[ "$status" -eq 127 ]]
    trap 'rm -rf ./spooky' RETURN
}

@test "gabr errors when a function is undefined" {
    source ./gabr.sh
    GABR_ENV=dev
    run gabr undefined
    echo failed-status-dev="\"${status}\"" 1>&2
    [[ "$status" -eq 1 ]]
    GABR_ENV=debug
    run gabr undefined
    echo failed-status-debug="\"${status}\"" 1>&2
    [[ "$status" -eq 1 ]]
    GABR_ENV=prod
    run gabr undefined
    echo failed-status-prod="\"${status}\"" 1>&2
    [[ "$status" -eq 1 ]]
}

@test "gabr errors when a function returns 1" {
    source ./gabr.sh
    GABR_ENV=dev
    run gabr return1
    [[ "$status" -eq 1 ]]
    GABR_ENV=debug
    run gabr return1
    [[ "$status" -eq 1 ]]
    GABR_ENV=prod
    run gabr return1
    [[ "$status" -eq 1 ]]
}

@test "gabr errors when a function returns 127" {
    source ./gabr.sh
    GABR_ENV=dev
    run gabr return127
    echo failed-status-dev="\"${status}\"" 1>&2
    [[ "$status" -eq 127 ]]
    GABR_ENV=debug
    run gabr return127
    echo failed-status-debug="\"${status}\"" 1>&2
    [[ "$status" -eq 127 ]]
    GABR_ENV=prod
    run gabr return127
    echo failed-status-prod="\"${status}\"" 1>&2
    [[ "$status" -eq 127 ]]
}

@test "gabr crashes shell when env is prod" {
    source ./gabr.sh
    GABR_ENV=dev
    result="$(echo $(gabr return1; echo "${?}-${GABR_ENV}_"))"
    GABR_ENV=debug
    result+="$(echo $(gabr return1; echo "${?}-${GABR_ENV}_"))"
    GABR_ENV=prod
    result+="$(echo $(gabr return1; echo "${?}-${GABR_ENV}_"))" # can not print exit code due to crash of shell
    echo failed-result="\"${result}\"" 1>&2
    [[ $result = "1-dev_1-debug_" ]]
}

@test "gabr does not walk over a error" {
    function undefined(){
        iamnotdefined;
        declare -x iamnotdefined=iamnotdefined
        return $?
    }
    local exitcode=0 # needs to be set to a variable in order to inherit Gabr's exitcode\
    source ./gabr.sh
    GABR_ENV=dev
    run gabr undefined;
    ! [[ -v iamnotdefined ]]
    GABR_ENV=debug
    run gabr undefined;
    ! [[ -v iamnotdefined ]]
    GABR_ENV=prod
    run gabr undefined;
    ! [[ -v iamnotdefined ]]
}

@test "Running and sourcing gabr only adds Gabr to scope" {
    function diffStack(){
        difference(){
            echo "${stack}" "${stack}" "$@" | tr ' ' '\n' | sort | uniq -u;
        }
        difference ${@} 
    }
    local herestack=$(declare -F -f)
    source ./gabr.sh
    local -a result=($(
        gabr diffStack $(declare -F -f);
        echo -;
        gabr diffStack $(declare -F -f)
        echo -;
        echo "${herestack}" "${herestack}" "$(declare -F -f)" | tr ' ' '\n' | sort | uniq -u
    ))
    local str=$(IFS=$' '; echo ${result[*]})
    echo failed-result=$str 1>&2
    [[ $str = "- - gabr" ]]

}

@test "Gabr can find a file and run it's functions" {
    echo "\
function sayhi(){
    echo hi
}
function saybye(){
    echo bye
}" > ./sayhi.sh
    source ./gabr.sh
    local result="$(gabr ./sayhi.sh sayhi) $(gabr ./sayhi.sh) $(gabr sayhi) $(gabr ./sayhi.sh saybye)"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./sayhi.sh' RETURN
    [[ $result  = 'hi hi hi bye' ]]
}

@test "Gabr does not alter spaces in arguments" {
    echo "\
function whatdidisay(){
    echo \"\${@}\"
}" > ./whatdidisay.sh
    source ./gabr.sh
    local result="$(gabr whatdidisay ' jim ' " has long " " cheeks ")"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./whatdidisay.sh' RETURN
    [[ $result  = ' jim   has long   cheeks ' ]]
}

@test "Gabr sees tabs as separator" {
    echo "\
function spectabular(){
    echo \"\${@}\"
}" > ./spectabular.sh
    source ./gabr.sh
    local result="$(gabr spectabular "$(echo -e '\t')<tabs>$(echo -e '\t')" "<ta$(echo -e '\t')bs>")"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./spectabular.sh' RETURN
    [[ "$result"  = "<tabs> <ta bs>" ]]
}


@test "Gabr has minimal api when file, directory and function named the same" {
    mkdir -p 'sophie'
    echo "\
function sophie(){
    echo Sophie
}" > sophie/sophie.sh
    source ./gabr.sh
    local result="$(gabr sophie)"
    trap 'rm -rf sophie' RETURN
    [[ "$result"  = "Sophie" ]]
}

@test "Gabr runs in directory relative to file in which function is called" {
    mkdir -p 'whereru'
    echo "\
function whereru(){
    echo \${PWD}
}
" > whereru/whereru.sh
    source ./gabr.sh
    local localPWD=$(pwd)
    local result="$(gabr whereru)"
    echo failed-result="\"${result[@]: -8}\"" 1>&2
    trap 'rm -rf whereru' RETURN
    [[ "${result[@]: -8}"  = "/whereru" ]]
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
    source ./gabr.sh
    local result="$(gabr $(gabr .jimtest jim))"
    echo result="\"${result}\"" 1>&2
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -rf .jimtest' RETURN
    [[ "$result"  = "de wever" ]]
}

@test "Gabr fails on overly recursive calls (max 50)" {
    ! [[ "$(gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr gabr filename)" ]]
}