#!/bin/bash

# Delete all local branches
for branch in $(git branch); do
    echo "git branch -D $branch"
done

# Delete all remote branches
for branch in $(git branch -r | grep -v HEAD | awk -F/ '{print $2}'); do
    echo "git push origin --delete $branch"
done