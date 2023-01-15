#!/bin/bash
gitUsername=""
gitToken=""
domain="https://github.com"
displayName="NNW"
slugName=$( echo "$displayName" | awk '{print tolower($0)}')
repo="NickNetworks/$slugName"
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
    sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName" >/dev/null
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
            echo "$pathAt"
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
#     sudo chown $USER:$USER "$scriptDir"
    cd "$scriptDir"
    git fetch --all
    git reset --hard origin/master
    sudo chmod +x "$scriptDir/$wrapperName"
    sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
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
fi
