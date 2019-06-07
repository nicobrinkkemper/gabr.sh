# UNDEFINED FUNCTION
@test "gabrdebug errors when a function is undefined" {
    source ./gabrdebug.sh
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