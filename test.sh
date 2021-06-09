#!/bin/bash
gitUsername=""
gitToken=""
domain="https://git.nicknet.works"
displayName="NNW"
slugName=$( echo "$displayName" | awk '{print tolower($0)}')
repo="Bash/$slugName"
wrapperName="$slugName.sh"
installedName="$slugName"
binDir="/usr/bin"
scriptDir="/etc/$slugName"

##End Config Section. Don't edit below, unless you intend to change functionality.
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
execDir="$(pwd)"

echo "Args: $@"
echo "Count $#"
isolateScript()
{

    pathSoFar="."
    pathAt=1
    for w in "$@"; do
        let pathAt++
        pathSoFar="$pathSoFar/$w"
        if [  -f "$pathSoFar.sh" ]; then
            echo "$pathAt"
            return 0
        fi
    done
    return 1
}

cd "$scriptDir"
cmdEndIndex=$(isolateScript "$@")
if [[ $? -eq 1 ]]; then
    echo "No valid script called"
else
    script=${@:1:cmdEndIndex-1}
    script="${script// //}.sh"
    echo "Running $script"
    chmod +x "$script"
    args=""
    for a in "${@:cmdEndIndex}"; do
        args="$args \"$a\""
    done
    "$script" $args
    #wget -q -O "$execDir/nnw-script.sh" "$rawViewPattern/$cmdEndIndex.sh"
    #"$execDir/nnw-script.sh"
    #rm "$execDir/nnw-script.sh"
fi
