function return1()(
    exitcode=1
    return 1
)

function debug(){
    echo failed-status="\"${status}\"" 1>&2
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
    source ./gabr.sh
    local result="$(gabr ./sayhi sayhi) $(gabr ./sayhi) $(gabr sayhi) $(gabr ./sayhi saybye)"
    echo failed-result="\"${result}\"" 1>&2
    trap 'rm -f ./sayhi.sh' RETURN
    [ "$result"  = 'sourcedhi sourced sourcedhi sourcedbye' ]
}

@test "Gabr errors the same return code" {
    source ./gabr.sh
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
    run gabr boo
    debug
    [ $status -eq 123 ]
    run gabr baa
    debug
    [ "$status" -eq 123 ]
    run bash ./gabr.sh boo
    debug
    [ $status -eq 123 ]
    run bash ./gabr.sh baa
    debug
    trap 'rm -rf ./boo; rm -f ./baa.sh' RETURN
    [ "$status" -eq 123 ]
}

@test "Gabr errors when a file is not found" {
    source ./gabr.sh
    mkdir -p spooky
    mkdir -p spooky/scary
    run gabr spooky
    debug
    output=${output}
    [ "$status" -eq 1 ]
    [ "${output##*\'spooky\'}" != "${output}" ]
    run gabr spooky scary skeleton
    debug
    trap 'rm -rf ./spooky' RETURN
    output=${output}
    [ "$status" -eq 1 ]
    [ "${output##*\'skeleton\'}" != "${output}" ]
}

@test "gabr errors when a function is undefined" {
    source ./gabr.sh
    run gabr undefined
    debug
    [ "$status" -eq 1 ]
}

@test "gabr errors when a function returns 1" {
    source ./gabr.sh
    run gabr return1
    debug
    [ "$status" -eq 1 ]
}

@test "gabr can change default functionality with GABR_DEFAULT/default" {
    source ./gabr.sh
    run gabr
    normalOutput=$output
    debug
    ! [ "${output##*gabr\:}" = "${output}" ]
    GABR_DEFAULT=help
    cp ./usage.sh ./help.sh
    run gabr
    helpOutput=$output
    debug
   # trap 'rm -f ./help.sh' RETURN
    [ "$helpOutput" = "$normalOutput" ]
    run gabr
    debug
    [ "$output" = "$helpOutput" ]
    local help='some-string' # this will be used by variable indirection
    run gabr
    debug
    [ "$output" = "some-string" ]
    function help(){
        echo 'some-other-string'
    }
    run gabr
    debug
    [ "$output" = "some-other-string" ]
}

@test "gabr can't be abused to execute malicious code through GABR_DEFAULT" {
    source ./gabr.sh
    GABR_DEFAULT='hi; exit 133; ho'
    run gabr
    debug
    ! [ "${output##*Warning\:}" = "${output}" ]
    GABR_DEFAULT='hack'
    declare hack="echo hacked; >&2; | eval exit 777; || echo hi && echo ho << exit 4"
    run gabr hack
    debug
    [ "${output}" = "${hack}" ]
}

@test "gabr does not walk over a error" {
    function dontwalkover()(
        return1
        echo nowido
        ( return $? );
    )
    source ./gabr.sh
    run gabr dontwalkover;
    [ "$status" -eq 1 ]
    [ "$output" = "" ]
    GABR_STRICT_MODE=off
    run gabr dontwalkover;
    [ "$status" -eq 0 ]
    [ "$output" = "nowido" ]
}

@test "Gabr does not alter spaces in arguments" {
    echo "\
function whatdidisay(){
    echo \"\${@}\"
}" > ./whatdidisay.sh
    source ./gabr.sh
    run gabr whatdidisay ' jim ' " has long " " cheeks "
    debug
    trap 'rm -f ./whatdidisay.sh' RETURN
    [ "$output"  = ' jim   has long   cheeks ' ]
}

@test "Gabr sees tabs as separator" {
    echo "\
function spectabular(){
    echo \"\${@}\"
}" > ./spectabular.sh
    source ./gabr.sh
    run gabr spectabular "$(echo -e '\t')<tabs>$(echo -e '\t')" "<ta$(echo -e '\t')bs>"
    debug
    trap 'rm -f ./spectabular.sh' RETURN
    [ "$output"  = "<tabs> <ta bs>" ]
}


@test "Gabr has minimal api when file, directory and function named the same" {
    mkdir -p 'sophie'
    mkdir -p 'sophie/sophie'
    echo "\
function sophie(){
    echo Sophie
}" > sophie/sophie/sophie.sh
    source ./gabr.sh
    run gabr sophie
    debug
    trap 'rm -rf sophie' RETURN
    [ "$output"  = "Sophie" ]
}

@test "Gabr runs in directory relative to file in which function is called" {
    mkdir -p 'whereru'
    echo "\
function whereru(){
    echo \${PWD}
}
" > whereru/whereru.sh
    source ./gabr.sh
    run gabr whereru
    echo failed-result="\"${output: -8}\"" 1>&2
    [ "$status" -eq 0 ]
    trap 'rm -rf whereru' RETURN
    [ "${output: -8}"  = "/whereru" ]
}

@test "Gabr can cd to directories and run files, recursively" {
    mkdir -p 'jim'
    # w/ root:  Below file/function will run in ./jim
    # w/o root:  Below file will run in PWD and function will run in ./jim
    echo "\
local here1=\$PWD
function jim(){
    printf '%s ' \"jim\" >&2
    ! [ \"\$PWD\" = \"\$here1\" ] && return
    gabr willem
}" > jim/jim.sh
# w/ root:  Below file/function will run in ./jim
# w/ root:   Below file will run in PWD function will run in ./jim
echo "\
local here2=\$PWD
function willem(){
    printf '%s ' \"willem\" >&2
    ! [ \"\$PWD\" = \"\$here2\" ] && return
    gabr bonito
}" > jim/willem.sh
# same as willem
echo "\
local here3=\$PWD
#!/usr/bin/env bash
function bonito(){
    printf '%s ' \"bonito\" >&2
    ! [ \"\$PWD\" = \"\$here3\" ] && return
    printf \"de wever\" >&2
}" > jim/bonito.sh
    source ./gabr.sh
    run gabr jim
    debug
    [ "$output"  = 'jim willem bonito de wever' ]
    declare -x GABR_ROOT=${PWD}/jim
    source ./gabr.sh
    run gabr jim
    trap 'rm -rf jim' RETURN
    [ "$output"  = 'jim willem bonito de wever' ]
}