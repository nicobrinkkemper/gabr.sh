
source ./usage.sh # sets the default usage function for all files in this directory
# 'example' must be given as argument
if [ -n "${1:-}" ] && ! [ "${1}" = 'usage' ]; then
    declare usageFiles="" # disable file listing for arguments after 'example' argument
fi