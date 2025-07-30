#!/bin/bash
gitUsername=""
gitToken=""
domain="https://github.com/"
displayName="ZVPN"
slugName=$(echo "$displayName" | awk '{print tolower($0)}')
repo="ZiplineVPN/$slugName"
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

# Native color functions
reset="\e[0m"
bold="\e[1m"
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
magenta="\e[35m"
cyan="\e[36m"
red_bright='\033[91m'
green_bright='\033[92m'
yellow_bright='\033[93m'
blue_bright='\033[94m'
magenta_bright='\033[95m'
cyan_bright='\033[96m'

color() {
    local c="$1"
    shift
    echo -ne "${!c}$*${reset}"
}

echoc() {
    local c="$1"
    shift
    echo -ne "${!c}$*${reset}\n"
}

# Git-based version functions
getGitVersion() {
    local repo_path="$1"
    if [ -d "$repo_path/.git" ]; then
        local commit_count=$(git -C "$repo_path" rev-list --count HEAD 2>/dev/null)
        local current_hash=$(git -C "$repo_path" rev-parse --short HEAD 2>/dev/null)
        if [ -n "$commit_count" ] && [ -n "$current_hash" ]; then
            echo "${commit_count}-${current_hash}"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Structured logging functions
log_info() {
    echo -e "$(color cyan_bright "ℹ") $(color cyan "INFO") $(color white "$@")"
}

log_success() {
    echo -e "$(color green_bright "✓") $(color green "SUCCESS") $(color white "$@")"
}

log_warning() {
    echo -e "$(color yellow_bright "⚠") $(color yellow "WARNING") $(color white "$@")"
}

log_error() {
    echo -e "$(color red_bright "✗") $(color red "ERROR") $(color white "$@")" >&2
}

log_debug() {
    if [ $verbose -eq 1 ]; then
        echo -e "$(color magenta_bright "🔍") $(color magenta "DEBUG") $(color white "$@")"
    fi
}

log_step() {
    echo -e "$(color blue_bright "→") $(color blue "STEP") $(color white "$@")"
}

log_version() {
    local nnw_version=$(getGitVersion "$dir")
    local fork_version=$(getGitVersion "$scriptDir")
    
    echo -e "$(color cyan_bright "📦") $(color cyan "ZVPN") $(color white "v$(color yellow "$fork_version")")"
    if [ "$dir" != "$binDir" ] && [ "$nnw_version" != "unknown" ]; then
        echo -e "$(color blue_bright "🔧") $(color blue "WRAPPER") $(color white "v$(color yellow "$nnw_version")")"
    fi
}

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
        log_debug "$@"
    fi
}

err() {
    if [ $verbose -eq 0 ]; then
        log_error "$@"
    else
        log_error "$@"
    fi
}

printVersion() {
    log_version
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    "--version")
        version=1
        log_debug "Version flag detected, will print version and exit"
        shift
        ;;
    "--verbose")
        verbose=1
        log_debug "Verbosity enabled, will log lots of stuff!"
        shift
        ;;
    "--uninstall")
        uninstall=1
        log_warning "Uninstall flag detected, will uninstall $displayName"
        shift
        ;;
    "--reinstall")
        reinstall=1
        log_warning "Reinstall flag detected, will reinstall $displayName"
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
    err "Both uninstall and reinstall flags are set, this is not allowed"
    exit 1
fi

installWrapper() {
    log_step "Installing wrapper to system"
    
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
    
    log_success "Wrapper installed successfully"
    log_info "Binary: $binDir/$installedName"
    log_info "Script: $scriptDir/$wrapperName"
    log_info "Repository: $domain/$repo"
}

updateCheck() {
    log_step "Checking for repository updates"
    
    if [ ! -d "$scriptDir" ]; then
        err "Directory '$scriptDir' does not exist"
        exit 2
    fi

    if git -C "$scriptDir" remote update &>/dev/null; then
        if ! git -C "$scriptDir" diff --ignore-space-at-eol --quiet origin/main; then
            log_info "Remote repository has changes"
            local shaNow=$(git -C "$scriptDir" rev-parse HEAD)
            log_debug "Pre-update SHA: $shaNow"
            log_step "Updating local repository"
            
            if [ $verbose -eq 1 ]; then
                git -C "$scriptDir" reset --hard origin/main
                git -C "$scriptDir" fetch --all
            else
                git -C "$scriptDir" fetch --all &>/dev/null
                git -C "$scriptDir" reset --hard origin/main &>/dev/null
            fi
            
            if command -v sudo &>/dev/null; then
                sudo chmod +x "$scriptDir/$wrapperName"
                sudo ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
            else
                chmod +x "$scriptDir/$wrapperName"
                ln -sf "$scriptDir/$wrapperName" "$binDir/$installedName"
            fi
            
            log_success "Repository updated successfully"
            shaNow=$(git -C "$scriptDir" rev-parse HEAD)
            log_debug "Post-update SHA: $shaNow"
        else
            log_success "Repository is up-to-date"
        fi
    else
        log_warning "Error updating remote repository, cloning new repository"
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
#     log_warning "Uninstalling $displayName"
#     if command -v sudo &>/dev/null; then
#         sudo rm "$binDir/$installedName"
#     else
#         rm "$binDir/$installedName"
#     fi
#     log_success "Uninstalled $displayName"
#     exit 0
# fi

if [ ! "$dir" == "$binDir" ]; then
    log_step "Script not in $binDir, installing wrapper"
    installWrapper
    exit 0
else
    log_step "Script in $binDir, checking for updates"
    cd "$scriptDir"
    updateCheck

    if [ $verbose -eq 1 ]; then
        printVersion
    fi

    cmdEndIndex=$(isolateScript "$@")
    log_debug "Command end index: $cmdEndIndex"
    
    if [ $((cmdEndIndex - 1)) -lt 0 ]; then
        log_debug "Not a script, checking if directory"
        cmdEndIndex=$(isolateDir "$@")
        if [ $((cmdEndIndex - 1)) -gt 0 ]; then
            log_info "Directory listing requested"
            script=${@:1:cmdEndIndex-1}
            script="${script// //}"
            log_info "Directory: $script"
            echo -e "$(color cyan_bright "📁") $(color cyan "CONTENTS")"
            for file in "$script"/*; do
                if [[ -d "$file" ]]; then
                    echo -e "  $(color yellow "📁") $(color yellow "$(basename "$file")")"
                else
                    echo -e "  $(color green "📄") $(color green "$(basename "$file")")"
                fi
            done
        else
            log_debug "Not a directory, wrapper execution complete"
        fi
    else
        script=${@:1:cmdEndIndex-1}
        script="${script// //}.sh"
    fi
    
    if [ -f "$script" ]; then
        log_step "Executing script: $script"
        chmod +x "$script"
        args=""
        for a in "${@:cmdEndIndex}"; do
            args="$args \"$a\""
        done
        cd "$execDir"
        source "$scriptDir/$script" $args
    fi
fi
