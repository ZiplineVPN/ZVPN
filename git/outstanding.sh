#!/bin/bash

# Find all directories that are git repositories, recursively
while IFS= read -r -d '' git_dir; do
  # Check if there are any uncommitted changes
  if [[ $(git --git-dir="$git_dir" --work-tree="$git_dir" status --porcelain) ]]; then
    repo_url=$(git --git-dir="$git_dir" --work-tree="$git_dir" config --get remote.origin.url)
    branches_with_commits=$(git --git-dir="$git_dir" --work-tree="$git_dir" branch --list --no-color | while read branch; do git --git-dir="$git_dir" --work-tree="$git_dir" --no-pager log --oneline "$branch" | grep -q . && echo "$branch"; done)
    
    # Only print if there are branches with outstanding commits
    if [[ -n "$branches_with_commits" ]]; then
      repo_root=$(git --git-dir="$git_dir" --work-tree="$git_dir" rev-parse --show-toplevel)
      printf "Repo URL: %s\nBranches with outstanding commits: %s\nPath: %s\n\n" "$repo_url" "$branches_with_commits" "$repo_root"
    fi
  fi
done < <(find . -name ".git" -type d -prune -print0)