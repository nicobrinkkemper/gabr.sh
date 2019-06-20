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
    local result="$(gabr ./sayhi.sh sayhi) $(gabr ./sayhi.sh) $(gabr sayhi) $(gabr ./sayhi.sh saybye)"
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

@test "Gabr errors when a file exits or returns 1" {
    source ./gabr.sh
    mkdir -p spooky
    echo "\
return 1
" > spooky/spooky.sh
    run gabr spooky
    debug
    trap 'rm -rf ./spooky' RETURN
    [ "$status" -eq 1 ]
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
    source ./gabr.sh
    GABR_DEFAULT='hi; exit 133; ho'
    run gabr
    debug
    ! [ "${output##*Warning\:}" = "${output}" ]
    GABR_DEFAULT='hack'
    declare hack="| echo hacked; eval exit 777; || echo hi && echo ho << exit 4"
    run gabr
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
    # since `jim` is not found, will jump to root, but it will step over 
    # changing directory because the first arguments does not use positional args. This is intentionally weird
    # but valid
    echo "\
function jim(){
    printf '%s ' jim >&2
    gabr jim/willem.sh willem
}" > jim/jim.sh
# since we recurse from jim to willem, below file will be called from jim directory
# however it will have to cd back to root in order to call the argument `jim/willem.sh`
echo "\
dir=\$(pwd)
function willem(){
    printf '%s ' willem >&2
    gabr bonito
}" > jim/willem.sh
# When a file is sourced, `gabr` will not have cd'd to the file's location just yet.
# That's why we can catch our location with `pwd`. Since dir will always be cd'd to,
# before a function call, willem can call below file.
echo "\
#!/usr/bin/env bash
function bonito(){
    printf '%s ' bonito >&2
    printf \"de wever\" >&2
}" > jim/bonito
    source ./gabr.sh
    run gabr jim
    debug
    trap 'rm -rf jim' RETURN
    [ "$output"  = 'jim willem bonito de wever' ]
}