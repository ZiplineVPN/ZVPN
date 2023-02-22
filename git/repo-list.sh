#!/bin/bash

# Set Gitea API URL and access token
GITEA_URL="https://git.nicknet.works"
GITEA_API_URL="${GITEA_URL}/api/v1"

real_run=0

while [[ $# -gt 0 ]]; do
    case $1 in
    "\"--real-run\"")
        real_run=1
        echo "REAL RUN! This script will actually make changes to Gitea."
        shift
        ;;
    *)
        echo "Invalid non-halting arg: '$1'"
        shift
        ;;
    esac
done

echo "Scanning repos in $(dirname "$repo")"
if [ $real_run -eq 1 ]; then
    echo "This is a: REAL RUN! This script WILL ACTUALLY make changes to Gitea."
    echo "It will create organizations and repositories in Gitea."
    echo "It will also adjust the remote URLs of the git repositories ENMASS."
    echo "Finally, it will push the git repositories to Gitea."
    echo "If you don't want to do this, then don't run this script with the --real-run flag."
    echo "Ctrl+C to cancel."
    echo
else
    echo "This is a DRY RUN! This script will NOT make any changes to Gitea."
    echo "It will only print the commands that would have been run."
    echo "If you want to make the changes to Gitea, and you are certain you're ready. Use the --real-run flag."
    echo
fi

# Prompt for Gitea API key
read -p "Enter your Gitea API key: " GITEA_API_KEY

# Find all git repositories in the current working directory and its subdirectories
find . -name ".git" -type d | while IFS= read -r repo; do
    # Get the path to the parent directory of the git repository
    repo_path="$(dirname "$repo")"

    # Get the remote URL
    remote_url=$(git --git-dir="$repo" --work-tree="$repo_path" remote get-url origin 2>/dev/null)

    # Check if the remote URL command failed
    if [ $? -ne 0 ]; then
        echo "Error: No such remote 'origin' in $repo_path."
        continue
    fi
    had_echo=0
    # Check if the remote URL is a Gitea URL
    if [[ $remote_url =~ ^(https?:\/\/)([^\/]+)\/([^\/]+)\/([^\/]+)\/?$ ]]; then
        org_name=${BASH_REMATCH[3]}
        repo_name=${BASH_REMATCH[4]%.git}

        #push the repo
        if [ $real_run -eq 1 ]; then
            git --git-dir="$repo" --work-tree="$repo_path" push --all origin
            echo "Pushing repo $repo_name in $repo_path."
            had_echo=1
        else
            echo "Push repo via: git --git-dir="$repo" --work-tree="$repo_path" push --all origin"
            had_echo=1
        fi
    else
        echo "Remote URL $remote_url for $repo_path is not a Gitea URL, skipping."
    fi
    if [ $had_echo -eq 1 ]; then
        echo
    fi
done
