
@test "Gabr returns non error code" {
    source ./gabr.sh
    gabr
    echo failed-result="\"${?}\"" 1>&2
    [[ $? -eq 0 ]]
}

function return127(){
    exitcode=127
    return 127
}

function return1(){
    exitcode=1
    return 1
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
    source ./boo/boo.sh
    GABR_ENV=prod
    run gabr boo
    GABR_ENV=dev
    run gabr boo
    [[ "$status" -eq 123 ]]
    result=$(gabr wah || echo $?)
    [[ "$result" -eq 1 ]]
}


@test "Gabr global errors when a file returns 127" {
    source ./gabrdebug.sh
    mkdir -p boo
    echo "\
spooky
" > boo/boo.sh
    GABR_ENV=prod
    result="$(exitcode=0; gabr boo >/dev/null; echo "${exitcode}.${?}--")"
    GABR_ENV=dev
    result+="$(exitcode=0; gabr boo >/dev/null; echo "${exitcode}.${?}--")"
    GABR_ENV=debug
    result+="$(exitcode=0; gabr boo >/dev/null; echo "${exitcode}.${?}")"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -rf boo' RETURN
    [[ $result = "127.127--127.0--127.0" ]]
}

# UNDEFINED FUNCTION
@test "gabrdebug errors when a function is undefined" {
    source ./gabr.sh
    GABR_ENV=prod
    exitcode=0;
    run gabr undefined;
    echo failed-status-prod="\"${status}\"" 1>&2
    echo failed-status-exitcode="\"${exitcode}\"" 1>&2
    [[ "$status" -eq 1 ]]
    GABR_ENV=dev
    exitcode=0;
    run gabr undefined;
    echo failed-status-dev="\"${status}\"" 1>&2
    [[ "$status" -eq 1 ]]
    GABR_ENV=debug
    exitcode=0;
    run gabr undefined;
    echo failed-status-debug="\"${status}\"" 1>&2
    [[ "$status" -eq 1 ]]
}

# FUNCTION RETURNS 1
@test "gabrdebug errors when a function returns 1" {
    source ./gabrdebug.sh
    GABR_ENV=prod
    result="$(exitcode=0; gabr return1 >/dev/null; echo "${exitcode}.${?}--")" # 1.1--
    GABR_ENV=dev
    result+="$(exitcode=0; gabr return1 >/dev/null; echo "${exitcode}.${?}--")" # 1.0--
    GABR_ENV=debug
    result+="$(exitcode=0; gabr return1 >/dev/null; echo "${exitcode}.${?}")" # 1.0
    echo failed-result="\"${result}\"" 1>&2
    [[ $result = "1.1--1.0--1.0" ]]
}

# FUNCTION RETURNS 127 DEV/DEBUG
@test "gabrdebug errors when a function returns 127" {
    local stack=$(declare -F)
    source ./gabrdebug.sh
    GABR_ENV=prod
    result="$(exitcode=0; gabr return127 >/dev/null; echo "${exitcode}.${?}--")" # 127.127--
    GABR_ENV=dev
    result+="$(exitcode=0; gabr return127 >/dev/null; echo "${exitcode}.${?}--")" # 127.0--
    GABR_ENV=debug
    result+="$(exitcode=0; gabr return127 >/dev/null; echo "${exitcode}.${?}")" # 127.0
    echo failed-result="\"${result}\"" 1>&2
    [[ $result = "127.127--127.0--127.0" ]]
}

@test "gabr does not walk over a error" {
    GABR_ENV=prod
    function undefined(){
        iamnotdefined;
        declare -x iamnotdefined=iamnotdefined
        return $?
    }
    local exitcode=0 # needs to be set to a variable in order to inherit Gabr's exitcode\
    source ./gabr.sh
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