#!/bin/bash

git branch | grep -v "main" | xargs echo #git branch -D

# Delete all remote branches
git branch -r | grep -v "main" | sed 's/origin\///' | xargs echo