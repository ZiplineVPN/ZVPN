#!/bin/bash

# Check if --real-run was provided
if [ $# -eq 0 ] || [ "$1" == "--real-run" ]; then
  real_run=1
  if [ $# -eq 0 ]; then
    real_run=0
  fi

  # Find all git repositories in the current working directory and its subdirectories
  find . -name ".git" -type d | while read repo
  do
    # Get the path to the parent directory of the git repository
    repo_path="$(dirname "$repo")"

    # Get the remote URL
    remote_url=$(git --git-dir="$repo" --work-tree="$repo_path" remote get-url origin 2>/dev/null)

    # Check if the remote URL command failed
    if [ $? -ne 0 ]; then
      echo "Error: No such remote 'origin' in $repo_path."
      continue
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
        echo "Remote URL for $repo_path is already set to $new_url, skipping update."
      fi
    fi
  done
else
  echo "Error: Invalid argument was provided."
  echo "Usage: $0 [--real-run]"
  exit 1
fi