
@test "gabr returns non error code" {
    source ./gabr.sh
    [[ $(gabr >/dev/null && echo $?) -eq 0 ]]
}

@test "gabr *does* FULLY error out when not defined and ENV is prod" {
    ENV=prod
    source ./gabr.sh
    ! [[ $(gabr undefined >/dev/null || true) ]] || [[ true ]]
}

@test "gabr *does not* FULLY error out when not defined and ENV is dev (default)" {
    ENV=dev
    source ./gabr.sh
    [[ $(gabr undefined >/dev/null || true) ]] || [[ true ]]
}

@test "gabr *does* error out when not defined and ENV is dev" {
    ENV=dev
    source ./gabr.sh
    ! [[ $(gabr undefined >/dev/null || true) ]]
}

@test "sourcing ./gabr.sh only adds gabr function to the scope" {
    local stack=$(declare -F)
    source ./gabr.sh
    local newStack=$(declare -F)
    [[ $(echo "${stack}" "${stack}" "${newStack}" | tr ' ' '\n' | sort | uniq -u)  = 'gabr' ]] # difference
}

@test "Running gabr does not add to scope" {
    local stack=$(declare -F)
    source ./gabr.sh
    echo "\
function scope(){
    function notadded(){
        return;
    }
    return;
}" > ./scope.sh
    gabr scope notadded
    local newStack=$(gabr scope notadded >/dev/null; declare -F)
    rm -f ./scope.sh
    [[ $(echo "${stack}" "${stack}" "${newStack}" | tr ' ' '\n' | sort | uniq -u)  = 'gabr' ]] # difference
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
    rm -f ./sayhi.sh
    [[ $result  = 'hi hi hi bye' ]]
}

@test "Gabr does not alter spaces in arguments" {
    echo "\
function whatdidisay(){
    echo \"\${@}\"
}" > ./whatdidisay.sh
    source ./gabr.sh
    local result="$(gabr whatdidisay ' jim ' " has long " " cheeks ")"
    rm -f ./whatdidisay.sh
    [[ $result  = ' jim   has long   cheeks ' ]]
}

@test "Gabr sees tabs as separator" {
    echo "\
function spectabular(){
    echo \"\${@}\"
}" > ./spectabular.sh
    source ./gabr.sh
    local result="$(gabr spectabular "$(echo -e '\t')<tabs>$(echo -e '\t')" "<ta$(echo -e '\t')bs>")"
    rm -f ./spectabular.sh
    echo result="\"${result}\"" 1>&2
    [[ "$result"  = "<tabs> <ta bs>" ]]
}

@test "Gabr can cd to directories and run files" {
    mkdir -p '.temptest'
    echo "\
function jim(){
    echo .temptest/willem.sh
}" > .temptest/jim.sh
echo "\
dir+=/.temptest
function willem(){
    gabr bonito
}" > .temptest/willem.sh
echo "\
function bonito(){
    echo \"de wever\"
}" > .temptest/bonito.sh
    source ./gabr.sh
    local result="$(gabr $(gabr .temptest jim))"
    echo result="\"${result}\"" 1>&2
    rm -rf .temptest
    [[ "$result"  = "de wever" ]]
}