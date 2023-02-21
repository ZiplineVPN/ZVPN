#!/bin/bash

# Set Gitea API URL and access token
GITEA_API_URL="https://git.nicknet.works/api/v1"
# Prompt for Gitea API key
read -p "Enter your Gitea API key: " GITEA_API_KEY

real_run=0

while [[ $# -gt 0 ]]
do
    case $1 in
        "\"--real-run\"")
        real_run=1
        echo "REAL RUN! This script will actually make changes to Gitea."
        shift
    ;;
    *)
        echo "Default case '$1'"
        shift
    ;;
    esac
done

# Find all git repositories in the current working directory and its subdirectories
for repo in $(find . -name ".git" -type d); do
    # Get the path to the parent directory of the git repository
    repo_path="$(dirname "$repo")"
    
    # Get the remote URL
    remote_url=$(git --git-dir="$repo" --work-tree="$repo_path" remote get-url origin 2>/dev/null)
    
    # Check if the remote URL command failed
    if [ $? -ne 0 ]; then
        echo "Error: No such remote 'origin' in $repo_path."
        continue
    fi
    # Check if the remote URL is a Gitea URL
    if [[ $remote_url =~ ^(https?:\/\/)([^\/]+)\/([^\/]+)\/([^\/]+)\/?$ ]]; then
        org_name=${BASH_REMATCH[3]}
        repo_name=${BASH_REMATCH[4]}
        
        # Check if the organization already exists in Gitea
        org_resp=$(curl --silent -H "Authorization: token $GITEA_API_KEY" -X GET "$GITEA_API_URL/orgs/$org_name")
        if [[ "$org_resp" == *"user redirect does not exist"* ]]; then
            # Create the organization in Gitea
            if [ $real_run -eq 1 ]; then
                curl -H 'Content-Type: application/json' -H "Authorization: token $GITEA_API_KEY" -X POST "$GITEA_API_URL/orgs" -d "{\"username\": \"$org_name\", \"visibility\":\"limited\"}"
                echo "Created organization $org_name for repo $repo_name in $repo_path."
            else
                echo "Make org via: curl -H 'Authorization: token $GITEA_API_KEY' -X POST '$GITEA_API_URL/orgs' -d {\"username\": \"$org_name\"}"
            fi
        else
            echo "Organization $org_name already exists in Gitea, skipping creation."
            echo
        fi
        
        # Check if the remote URL contains username and password
        if [[ $remote_url =~ ^https://([^:]+):([^@]+)@.*$ ]]; then
            # Remove the username and password from the URL
            new_url="https://${remote_url#*//}"
            new_url="${new_url#*:*@}"
            new_url="https://${new_url}"
            
            # Check if the new URL is different from the current URL
            if [ "$remote_url" != "$new_url" ]; then
                if [ $real_run -eq 1 ]; then
                    # Update the remote URL
                    git --git-dir="$repo" --work-tree="$repo_path" remote set-url origin "$new_url"
                    echo "Updated remote URL for $repo_path: $new_url"
                else
                    # Print the command that would have been run
                    echo "git --git-dir=$repo --work-tree=$repo_path remote set-url origin $new_url"
                fi
            else
                echo "Remote URL for $repo_path is already set to $new_url, skipping url update."
                echo
            fi
        fi
        
        # Check if the repo already exists in the organization
        org_resp=$(curl --silent -H "Authorization: token $GITEA_API_KEY" -X GET "$GITEA_API_URL/repos/$repo_name")
        if [[ "$org_resp" == "404 page not found" ]]; then
            # Create the repo in Gitea
            if [ $real_run -eq 1 ]; then
                
                curl -H "Authorization: token $GITEA_API_KEY" -X POST "$GITEA_API_URL/user/repos" -H 'accept: application/json' -H 'Content-Type: application/json' -d "{ \"name\": \"$repo_name\"}"
                echo "Created organization $org_name for repo $repo_name in $repo_path."
            else
                echo "Make org repo via: curl -H "Authorization: token $GITEA_API_KEY" -X POST "$GITEA_API_URL/user/repos" -H 'accept: application/json' -H 'Content-Type: application/json' -d \"{ \"name\": \"$repo_name\"}\""
                echo
            fi
        else
            echo "Repo $repo_name already exists in Org $org_name, skipping creation."
        fi
    else
        echo "Remote URL $remote_url for $repo_path is not a Gitea URL, skipping."
    fi
    
    
done