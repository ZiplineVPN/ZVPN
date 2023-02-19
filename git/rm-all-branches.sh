#!/bin/bash

# Delete all local branches
for branch in $(git branch | cut -c 3-); do
  if [[ $branch != "main" ]]; then
    echo "git branch -D $branch"
  fi
done

# Delete all remote branches
for branch in $(git branch -r | grep -v HEAD | awk -F/ '{print $2}'); do
  if [[ $branch != "wip" ]]; then
    echo "git push origin --delete $branch"
  fi
done