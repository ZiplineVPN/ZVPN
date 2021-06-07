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
    old="$IFS"
    IFS='/'
    relativeCmd="$*"
    IFS=$old
    if [ -n "$relativeCmd" ]; then
        echo "Running $relativeCmd"
        chmod +x "$relativeCmd.sh"
        "./$relativeCmd.sh"
        #wget -q -O "$execDir/nnw-script.sh" "$rawViewPattern/$relativeCmd.sh"
        #"$execDir/nnw-script.sh"
        #rm "$execDir/nnw-script.sh"
    fi
fi
