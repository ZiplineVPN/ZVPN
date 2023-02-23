#!/bin/bash
gitUsername=""
gitToken=""
domain="https://git.nicknet.works"
displayName="ZVPN"
slugName=$( echo "$displayName" | awk '{print tolower($0)}')
repo="ZiplineVPN/$slugName"
installedName="$slugName"
binDir="/usr/bin"
scriptDir="/etc/$slugName"

##End Config Section. Don't edit below, unless you intend to change functionality.

wrapperName="nnw.sh"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
execDir="$(pwd)"

#handle arguments
verbose=0
uninstall=0
reinstall=0

if [ -d "$scriptDir/includes" ]; then
    for file in "$scriptDir/includes"/*.sh; do
        if [ -f "$file" ]; then
            source "$file"
        fi
    done
fi

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

while [[ $# -gt 0 ]]; do
    case "$1" in
    "--verbose" | "--v")
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
        ec red_bright "Uninstall flag detected, will uninstall $(c yellow "$displayName")"
        shift
        ;;
    *)
        break
        ;;
    esac
done

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
    ec "Checking for updates..."
    if [ ! -d "$scriptDir" ]; then
        err "Error: directory '$scriptDir' does not exist"
        exit 1
    fi

    if git -C "$scriptDir" remote update; then
        if ! git -C "$scriptDir" diff --ignore-space-at-eol --quiet origin/main; then
            ec cyan "Remote repository has changes."
            shaNow=$(git -C "$scriptDir" rev-parse HEAD)
            ec cyan "Pre update SHA: $(color yellow "$shaNow")"
            ec yellow "Updating local repository..."
            git -C "$scriptDir" fetch --all
            git -C "$scriptDir" reset --hard origin/main
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
        git clone --depth 1 "$domain/$repo" "$scriptDir"
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
# isolateScript "$@"

if [ ! "$dir" == "$binDir" ]; then
    installWrapper
    exit
else
    #     sudo chown $USER:$USER "$scriptDir"
    cd "$scriptDir"
    updateCheck

    cmdEndIndex=$(isolateScript "$@")
    if [ $((cmdEndIndex - 1)) -lt 0 ]; then
        cmdEndIndex=$(isolateDir "$@")
        if [ $((cmdEndIndex - 1)) -gt 0 ]; then
            script=${@:1:cmdEndIndex-1}
            script="${script// //}"
            ec red "Script '$script' is a directory."
            ec cyan "Available scripts and subdirectories in this directory are:"
            ec cyan "Scripts are $(color green "green and bold") and directories are $(color yellow "yellow and italic")"
            for file in "$script"/*; do
                if [[ -d "$file" ]]; then
                    ec italic "\t- $(color yellow "$(basename "$file")")"
                else
                    ec bold "\t- $(color green "$(basename "$file")")"
                fi
            done
        fi
    else
        script=${@:1:cmdEndIndex-1}
        script="${script// //}.sh"
    fi
    if [ -f "$script" ]; then
        ec green "Running $script"
        git -C "$scriptDir" reset --hard origin/main
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
