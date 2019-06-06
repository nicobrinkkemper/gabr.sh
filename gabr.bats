
@test "Gabr returns non error code" {
    source ./gabr.sh
    gabr debug
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

# BAD FILE
@test "Gabr errors when a file returns 127" {
    source ./gabr.sh
    mkdir -p boo
    echo "\
spooky
function spooky(){
    return 127
}
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
@test "gabr errors when a function is undefined" {
    source ./gabr.sh
    GABR_ENV=prod
    result="$(exitcode=0; gabr undefined >/dev/null; echo "${exitcode}.${?}--")" # 1.1--
    GABR_ENV=dev
    result+="$(exitcode=0; gabr undefined >/dev/null; echo "${exitcode}.${?}--")" # 1.0--
    GABR_ENV=debug
    result+="$(exitcode=0; gabr undefined >/dev/null; echo "${exitcode}.${?}")" # 1.0
    echo failed-result="\"${result}\"" 1>&2
    [[ $result = "1.1--1.0--1.0" ]]
}

# FUNCTION RETURNS 1
@test "gabr errors when a function returns 1" {
    source ./gabr.sh
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
@test "Gabr errors when a function returns 127" {
    local stack=$(declare -F)
    source ./gabr.sh
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
    if ! gabr undefined; then
        echo exitcode=$exitcode >&2
        ! [[ -v iamnotdefined ]]
    fi
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