#!/bin/bash

# Delete all local branches
for branch in $(git branch | cut -c 3-); do
  if [[ $branch != "master" ]]; then
    echo "git branch -D $branch"
  fi
done

# Delete all remote branches
for branch in $(git branch -r | grep -v HEAD | awk -F/ '{print $2}'); do
  echo "git push origin --delete $branch"
done