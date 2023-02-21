#!/bin/bash
gitUsername=""
gitToken=""
domain="https://git.nicknet.works"
displayName="NNW"
slugName=$( echo "$displayName" | awk '{print tolower($0)}')
repo="NickNet.works/$slugName"
wrapperName="$slugName.sh"
installedName="$slugName"
binDir="/usr/bin"
scriptDir="/etc/$slugName"

##End Config Section. Don't edit below, unless you intend to change functionality.
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
execDir="$(pwd)"

installWrapper()
{
    if command -v sudo &> /dev/null; then
        sudo rm -rf "$scriptDir"
        sudo mkdir -p "$scriptDir"
        sudo chown $USER:$USER "$scriptDir"
    else
        rm -rf "$scriptDir"
        mkdir -p "$scriptDir"
        chown $USER:$USER "$scriptDir"
    fi
    updateCheck
    if command -v sudo &> /dev/null; then
        sudo rm "$binDir/$installedName"
        sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName" >/dev/null
        sudo chmod +x "$scriptDir/$wrapperName"
    else
        rm "$binDir/$installedName"
        ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName" >/dev/null
        chmod +x "$scriptDir/$wrapperName"
    fi
    echo "$displayName installed as '$installedName'"
    echo "      Repo link?          $domain/$repo"
    echo "      This $displayName's name?    $wrapperName"
    echo "      Where?              $binDir/$installedName"
    echo "Ready to rollout!"
}

updateCheck()
{
    echo "Checking for updates..."
    if git -C "$scriptDir" remote update; then
        if ! git -C "$scriptDir" diff --quiet origin/main; then
            echo "Remote repository has changes. Current SHA: $(git -C "$scriptDir" rev-parse HEAD) Updating local repository..."
            git -C "$scriptDir" reset --hard origin/main
            if command -v sudo &> /dev/null; then
                sudo chmod +x "$scriptDir/$wrapperName"
                sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
            else
                chmod +x "$scriptDir/$wrapperName"
                ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
            fi
            echo "Local repository has been updated from remote repository. Current SHA: $(git -C "$scriptDir" rev-parse HEAD)"
        else
            echo "Local repository is up-to-date with remote repository."
        fi
    else
        echo "Error updating remote repository. Cloning new repository..."
        git clone "$domain/$repo" "$scriptDir"
    fi
}

isolateScript()
{
    
    pathSoFar="."
    pathAt=1
    for w in "$@"; do
        let pathAt++
        pathSoFar="$pathSoFar/$w"
        if [ -f "$pathSoFar.sh" ]; then
            echo "$pathAt"
            return 0
        fi
    done
    return 1
}

isolateDir()
{
    
    pathSoFar="."
    pathAt=1
    for w in "$@"; do
        let pathAt++
        pathSoFar="$pathSoFar/$w"
        if [ -d "$pathSoFar" ]; then
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
    cd ""
    updateCheck
    cmdEndIndex=$(isolateScript "$@")
    echo $((cmdEndIndex-1))
    if [ $((cmdEndIndex-1)) -lt 0 ]; then
        cmdEndIndex=$(isolateDir "$@")
        if [ $((cmdEndIndex-1)) -gt 0 ]; then
            script=${@:1:cmdEndIndex-1}
            script="${script// //}"
            echo "Script '$script' is a directory. Available scripts and subdirectories in this directory are:"
            for file in "$script"/*; do
                if [[ -d "$file" ]]; then
                    echo " - $(basename "$file") (directory)"
                else
                    echo " - $(basename "$file")"
                fi
            done
            exit;
        fi
    fi
    script=${@:1:cmdEndIndex-1}
    script="${script// //}"
    echo "Script '$script' is a file. Running it..."
    if [ -f "$dir/$script" ]; then
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
