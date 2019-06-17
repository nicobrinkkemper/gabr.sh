function return1(){
    exitcode=1
    return 1
}

function debug(){
    echo failed-status-${GABR_ENV:-dev}="\"${status}\"" 1>&2
    echo failed-output="\"${output}\"" 1>&2
    echo BASH_VERSION="\"${BASH_VERSION}\"" 1>&2
}

if ! [ -f "./gabr.sh" ]; then
    if [ -f "/opt/gabr/gabr.sh" ]; then
        cd /opt/gabr/
    else
        echo PWD=$PWD 1>&2
        echo "Can't find gabr.sh" 1>&2
        (exit 1)
    fi
fi


@test "Gabr can find a file and run it's functions" {
    echo "\
printf %s sourced
function sayhi(){
    printf %s hi
}
function saybye(){
    printf %s bye
}" > ./sayhi.sh
    source gabr.sh
    local result="$(gabr ./sayhi.sh sayhi) $(gabr ./sayhi.sh) $(gabr sayhi) $(gabr ./sayhi.sh saybye)"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./sayhi.sh' RETURN
    [ "$result"  = 'sourcedhi sourced sourcedhi sourcedbye' ]
}

@test "Gabr returns non error code" {
    source gabr.sh
    run gabr
    debug
    [ $status -eq 0 ]
}

@test "Gabr errors the same return code" {
    source gabr.sh
    mkdir -p boo
    echo "\
function boo()(
    echo boo >&2
    return 123
)
" > boo/boo.sh
    echo "\
function baa()(
    gabr gabr boo
)
" > baa.sh
    GABR_ENV=prod
    run gabr boo
    debug
    [ "$status" -eq 123 ]
    run gabr baa
    debug
    [ "$status" -eq 123 ]
    GABR_ENV=debug
    run gabr boo
    debug
    [ "$status" -eq 123 ]
    run gabr boo baa
    debug
    [ "$status" -eq 123 ]
    GABR_ENV=prod
    run gabr boo
    debug
    [ "$status" -eq 123 ]
    run gabr baa
    debug
    [ "$status" -eq 123 ]
    trap 'rm -rf ./boo; rm -f ./baa.sh' RETURN
}

@test "Gabr global errors when a file exits" {
    source gabr.sh
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
    source gabr.sh
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
    source gabr.sh
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
    source gabr.sh
    GABR_ENV=dev
    result="$(echo $(gabr return1; echo "${GABR_ENV}_"))"
    GABR_ENV=debug
    result+="$(echo $(gabr return1; echo "${GABR_ENV}_"))"
    GABR_ENV=prod
    result+="$(echo $(gabr return1; echo "${GABR_ENV}_"))" # can not print due to crash of shell
    echo failed-result="\"${result}\"" 1>&2
    [ $result = "dev_debug_" ]
}

@test "gabr can change default functionality with GABR_DEFAULT/default" {
    source gabr.sh
    GABR_ENV=dev
    local normalOutput="$(gabr 2>&1)"
    echo failed-normalOutput="\"${normalOutput}\"" 1>&2
    [ -n "$normalOutput" ]
    GABR_DEFAULT=help
    local helpOutput="$(gabr 2>&1)"
    echo failed-helpOutput="\"${helpOutput}\"" 1>&2
    [ "$helpOutput" = "$normalOutput" ]
    local helpDirectCallOutput="$(gabr help 2>&1)"
    echo failed-helpDirectCallOutput="\"${helpDirectCallOutput}\"" 1>&2
    [ "$helpDirectCallOutput" = "$helpOutput" ]
    local help='some-string' # this will be used by variable indirection
    local helpStringOutput="$(gabr 2>&1)"
    echo failed-helpStringOutput="\"${helpStringOutput}\"" 1>&2
    [ "$helpStringOutput" = "some-string" ]
    function help(){
        echo 'some-other-string'
    }
    local helpFunctionOutput="$(gabr 2>&1)"
    echo failed-helpFunctionOutput="\"${helpFunctionOutput}\"" 1>&2
    [ "$helpFunctionOutput" = "some-other-string" ]
}

@test "gabr can't be abused to execute malicious code through GABR_DEFAULT" {
    source gabr.sh
    GABR_ENV=dev
    GABR_DEFAULT='hi; exit 133; ho'
    declare warningOutput="$(gabr 2>&1)"
    echo failed-warningOutput="\"${warningOutput}\"" 1>&2
    ! [ "${warningOutput##*Warning\:}" = "${warningOutput}" ]
    GABR_DEFAULT='hack'
    declare hack="| echo hacked; eval exit 777; || echo hi && echo ho << exit 4"
    declare hackOutput="$(gabr 2>&1)"
    echo failed-hackOutput="\"${hackOutput}\"" 1>&2
    [ "${hackOutput}" = "${hack}" ]
}

@test "gabr does not walk over a error" {
    function undefined(){
        iamnotdefined;
        declare -x iamnotdefined=iamnotdefined
        return $?
    }
    local exitcode=0 # needs to be set to a variable in order to inherit Gabr's exitcode\
    source gabr.sh
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
    source gabr.sh
    local stack="$(declare -F)"
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


@test "Gabr does not alter spaces in arguments" {
    echo "\
function whatdidisay(){
    echo \"\${@}\"
}" > ./whatdidisay.sh
    source gabr.sh
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
    source gabr.sh
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
    source gabr.sh
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
    source gabr.sh
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
    echo .jimtest/willem.sh willem
}" > .jimtest/jim.sh
echo "\
dir="\${dir:-.}/.jimtest"
function willem(){
    echo willem >&2
    gabr bonito bonito
}" > .jimtest/willem.sh
echo "\
function bonito(){
    echo bonito >&2
    echo \"de wever\"
}" > .jimtest/bonito
    source gabr.sh
    local result="$(gabr $(gabr .jimtest jim))"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -rf .jimtest' RETURN
    [ "$result"  = "de wever" ]
}