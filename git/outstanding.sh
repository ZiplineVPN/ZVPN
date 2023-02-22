#!/bin/bash

# Find all directories that are git repositories, recursively
while IFS= read -r -d '' git_dir; do
    # Check if there are any uncommitted changes or unpushed commits
    if [[ $(git --git-dir="$git_dir" --work-tree="$git_dir" status --porcelain) || $(git --git-dir="$git_dir" --work-tree="$git_dir" log @{u}..HEAD) ]]; then
        current_branch=$(git --git-dir="$git_dir" --work-tree="$git_dir" rev-parse --abbrev-ref HEAD)
        echo "There are uncommitted changes or outstanding commits on branch '$current_branch'"
        git --git-dir="$git_dir" --work-tree="$git_dir" for-each-ref refs/heads --format='%(refname:short)' | while read branch; do
            [[ $(git --git-dir="$git_dir" --work-tree="$git_dir" status --porcelain "$branch") || $(git --git-dir="$git_dir" --work-tree="$git_dir" log "$branch..$branch@{u}") ]] && echo "Branch '$branch' has uncommitted changes or outstanding commits"
        done
    fi
done < <(find . -name '.git' -type d -print0)
