#!/bin/bash

if [ "$1" == "--real-run" ]; then
  real_run=true
else
  real_run=false
fi

echo "Deleting local branches except master..."
for branch in $(git branch | cut -c 3-); do
  if [[ $branch != "master" ]]; then
    if [ "$real_run" = true ]; then
      git branch -D $branch
      echo "Deleted local branch $branch"
    else
      echo "Would delete local branch $branch"
    fi
  fi
done

echo "Deleting remote branches except master..."
for branch in $(git branch -r | grep -v HEAD | awk -F/ '{print $2}'); do
  if [[ $branch != "master" ]]; then
    if [ "$real_run" = true ]; then
      git push origin --delete $branch
      echo "Deleted remote branch $branch"
    else
      echo "Would delete remote branch $branch"
    fi
  fi
done