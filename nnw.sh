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

installWrapper()
{
    sudo rm -rf "$scriptDir"
    sudo mkdir -p "$scriptDir"
    sudo chown $USER:$USER "$scriptDir"
    git clone "$domain/$repo" "$scriptDir"
    sudo rm "$binDir/$installedName"
    sudo ln -s "$scriptDir/$wrapperName" "$binDir/$installedName"
    sudo chmod +x "$scriptDir/$wrapperName"
    echo "$displayName installed as '$installedName'"
    echo "      Repo link?          $domain/$repo"
    echo "      This $displayName's name?    $wrapperName"
    echo "      Where?              $binDir/$installedName"
    echo "Ready to rollout!"
}

isolateScript()
{

    pathSoFar="."
    pathAt=1
    for w in "$@"; do
        let pathAt++
        pathSoFar="$pathSoFar/$w"
        if [  -f "$pathSoFar.sh" ]; then
            echo "$pathSoFar.sh ${@:$pathAt}"
            return 0
        fi
    done
    return 1
}
# isolateScript "$@"

if [ ! "$dir" == "$binDir" ]; then
    installWrapper
    exit
else
    sudo chown $USER:$USER "$scriptDir"
    cd "$scriptDir"
    git fetch --all
    git reset --hard origin/master
    sudo chmod +x "$scriptDir/$wrapperName"
    sudo ln -s "$scriptDir/$wrapperName" "$binDir/$installedName"
    relativeCmd=$(isolateScript "$@")
    if [[ $? -eq 1 ]]; then
        echo "No valid script called"
    else
        echo "Valid script: $relativeCmd"
    fi
    if [ -n "$relativeCmd" ]; then
        echo "Running $relativeCmd"
        chmod +x "$relativeCmd"
        "$relativeCmd"
        #wget -q -O "$execDir/nnw-script.sh" "$rawViewPattern/$relativeCmd.sh"
        #"$execDir/nnw-script.sh"
        #rm "$execDir/nnw-script.sh"
    fi
fi
