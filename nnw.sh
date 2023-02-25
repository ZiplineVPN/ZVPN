#!/bin/bash
gitUsername=""
gitToken=""
domain="https://git.nicknet.works"
displayName="NNW"
slugName=$(echo "$displayName" | awk '{print tolower($0)}')
repo="NickNet.works/$slugName"
installedName="$slugName"
binDir="/usr/bin"
scriptDir="/etc/$slugName"

##End Config Section. Don't edit below, unless you intend to change functionality.
# Exit codes
# 0: Script completed successfully.
# 1: Error due to "uninstall" and "reinstall" flags being set at the same time.
# 2: Error due to the script directory not existing.
# 3: Error updating remote repository, and couldn't clone a new repository.

wrapperName="nnw.sh"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
execDir="$(pwd)"

#Preload includes
if [ -d "$scriptDir/includes" ]; then
    for file in "$scriptDir/includes"/*.sh; do
        if [ -f "$file" ]; then
            source "$file"
        fi
    done
fi

#handle arguments
verbose=0
version=0
uninstall=0
reinstall=0

c() {
    if [ $verbose -eq 1 ]; then
        color "$@"
    fi
}

ec() {
    if [ $verbose -eq 1 ]; then
        echoc "$@"
    fi
}

err() {
    if [ $verbose -eq 0 ]; then
        echo "$(echoc red_bright "$@")" >&2
    else
        echoc red_bright "$@"
    fi
}

printVersion() {
    if [ ! -z ${NNW_VERSION+x} ]; then
        if [ ! -z ${NNW_FORK_VERSION+x} ]; then
            echoc cyan "$(color blue NNW)[$(color yellow "$NNW_VERSION")]: as $(color magenta "$displayName")[$(color yellow "$NNW_FORK_VERSION")]"
        else
            echoc cyan "$(color blue NNW)[$(color yellow "$NNW_VERSION")]: as $(color magenta "$displayName")"
        fi
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    "--version")
        version=1
        ec green_bright "Version flag detected, will print version and exit"
        shift
        ;;
    "--verbose")
        verbose=1
        ec green_bright "Verbosity enabled, will log lots of stuff!"
        shift
        ;;
    "--uninstall")
        uninstall=1
        ec red_bright "Uninstall flag detected, will uninstall $(c yellow "$displayName")"
        shift
        ;;
    "--reinstall")
        reinstall=1
        ec red_bright "Reinstall flag detected, will reinstall $(c yellow "$displayName")"
        shift
        ;;
    *)
        break
        ;;
    esac
done

#check if version flag is set, if so print version and exit
if [ $version -eq 1 ]; then
    printVersion
    exit 0
fi

#check if uninstall and reinstall are both set, if so exit, that can't happen
if [ $uninstall -eq 1 ] && [ $reinstall -eq 1 ]; then
    err "Error: both uninstall and reinstall flags are set, this is not allowed"
    exit 1
fi

installWrapper() {
    if command -v sudo &>/dev/null; then
        sudo rm -rf "$scriptDir"
        sudo mkdir -p "$scriptDir"
        sudo chown $USER:$USER "$scriptDir"
    else
        rm -rf "$scriptDir"
        mkdir -p "$scriptDir"
        chown $USER:$USER "$scriptDir"
    fi
    updateCheck
    if command -v sudo &>/dev/null; then
        sudo rm "$binDir/$installedName"
        sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName" >/dev/null
        sudo chmod +x "$scriptDir/$wrapperName"
    else
        rm "$binDir/$installedName"
        ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName" >/dev/null
        chmod +x "$scriptDir/$wrapperName"
    fi
    echoc green "$(color magenta "$wrapperName") as $(color yellow "$displayName") installed"
    echoc green "      As?                 '$installedName'"
    echoc green "      Where?              $binDir/$installedName"
    echoc green "      Repo link?          $domain/$repo"
    echoc green "Ready to roooollout!"
}

updateCheck() {
    ec cyan "Checking for updates..."
    if [ ! -d "$scriptDir" ]; then
        err "Error: directory '$scriptDir' does not exist"
        exit 2
    fi

    if git -C "$scriptDir" remote update &>/dev/null; then
        if ! git -C "$scriptDir" diff --ignore-space-at-eol --quiet origin/main; then
            ec cyan "Remote repository has changes."
            shaNow=$(git -C "$scriptDir" rev-parse HEAD)
            ec cyan "Pre update SHA: $(color yellow "$shaNow")"
            ec yellow "Updating local repository..."
            if [ $verbose -eq 1 ]; then
                git -C "$scriptDir" fetch --all
            else
                git -C "$scriptDir" fetch --all &>/dev/null
            fi
            if command -v sudo &>/dev/null; then
                sudo chmod +x "$scriptDir/$wrapperName"
                sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
            else
                chmod +x "$scriptDir/$wrapperName"
                ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
            fi
            ec green "Local repository has been updated from remote repository."
            shaNow=$(git -C "$scriptDir" rev-parse HEAD)
            ec cyan "Post update SHA: $(color yellow "$shaNow")"
        else
            ec green "Local repository is up-to-date with remote repository."
        fi
    else
        err "Error updating remote repository. Cloning new repository..."
        git -C "$scriptDir" clone --depth 1 "$domain/$repo" "$scriptDir"
    fi
}

isolateScript() {

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

isolateDir() {

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

# TODO: Test this
# if [ $uninstall -eq 1 ]; then
#     ec red_bright "Uninstalling $(c yellow "$displayName")..."
#     if command -v sudo &>/dev/null; then
#         sudo rm "$binDir/$installedName"
#     else
#         rm "$binDir/$installedName"
#     fi
#     ec green "Uninstalled $(c yellow "$displayName")"
#     exit 0
# fi

if [ ! "$dir" == "$binDir" ]; then
    ec cyan "Script is not in $binDir, installing wrapper..."
    installWrapper
    exit 0
else
    #     sudo chown $USER:$USER "$scriptDir"
    ec cyan "Script is in $binDir, checking wrapper to see if its outdated..."
    cd "$scriptDir"
    updateCheck

    if [ $verbose -eq 1 ]; then
        printVersion
    fi

    cmdEndIndex=$(isolateScript "$@")
    ec cyan "cmdEndIndex: $cmdEndIndex"
    if [ $((cmdEndIndex - 1)) -lt 0 ]; then
        ec cyan "Wasn't a script, lets see if its a dir."
        cmdEndIndex=$(isolateDir "$@")
        if [ $((cmdEndIndex - 1)) -gt 0 ]; then
            ec cyan "It was a dir! Lets list the contents for the user."
            script=${@:1:cmdEndIndex-1}
            script="${script// //}"
            echoc red "Script '$script' is a directory."
            echoc cyan "Available scripts and subdirectories in this directory are:"
            echoc cyan "Scripts are $(color green "green") and directories are $(color yellow "yellow")"
            for file in "$script"/*; do
                if [[ -d "$file" ]]; then
                    echoc yellow "\t- $(basename "$file")"
                else
                    echoc green "\t- $(basename "$file")"
                fi
            done
        else
            ec cyan "It wasn't a dir either, looks like the user just wanted to run the wrapper. Maybe they want to update only?"
            ec green "We're done here."
        fi
    else
        script=${@:1:cmdEndIndex-1}
        script="${script// //}.sh"
    fi
    if [ -f "$script" ]; then
        ec green "Running $script"
        if [ $verbose -eq 1 ]; then
            git -C "$scriptDir" reset --hard origin/main
        else
            git -C "$scriptDir" reset --hard origin/main &>/dev/null
        fi
        chmod +x "$script"
        args=""
        for a in "${@:cmdEndIndex}"; do
            args="$args \"$a\""
        done
        cd "$execDir"
        source "$scriptDir/$script" $args
        #wget -q -O "$execDir/nnw-script.sh" "$rawViewPattern/$cmdEndIndex.sh"
        #"$execDir/nnw-script.sh"
        #rm "$execDir/nnw-script.sh"
    fi
fi
