#!/bin/bash

# find all directories containing a .git subdirectory
dirs=$(find . -name ".git" -type d -prune)

# iterate over each repo directory
for dir in $dirs; do
  # extract the parent directory (the repo's local path)
  local_path=$(dirname $dir)

  # check if the repo has any outstanding commits
  cd $local_path
  outstanding_commits=$(git log origin/main..HEAD)

  if [ -n "$outstanding_commits" ]; then
    # if there are outstanding commits, print repo details
    remote_url=$(git config --get remote.origin.url)
    branch_names=$(git branch --no-color | awk '/^\*/{print $2}')

    echo "Repo URL: $remote_url"
    echo "Outstanding branches: $branch_names"
    echo "Local path: $local_path"
  fi
done