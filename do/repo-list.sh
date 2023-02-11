#!/bin/bash

# Check if a root path is provided
if [ $# -eq 0 ]; then
  echo "Error: No root path provided."
  echo "Usage: $0 <root_path>"
  exit 1
fi

# Find all directories that contain a .git folder inside the provided root path
repo_directories=$(find "$1" -name ".git" -type d 2>/dev/null | sed "s/\/.git//g")

# Initialize an empty array to store the repo URLs
repo_urls=()

# Initialize a counter for the number of repos scanned
count=0

# Loop through each repo directory and extract the repo URL
for repo_dir in $repo_directories; do
  cd "$repo_dir"
  url=$(git config --get remote.origin.url)
  repo_urls+=("$url")
  cd - > /dev/null

  # Increment the counter and update the display
  count=$((count + 1))
  printf "\rNumber of repos scanned: %d" $count
done

# Print the first and second directories of each repo URL
echo "\n\nList of Repos: "
for url in "${repo_urls[@]}"; do
  user=$(echo "$url" | awk -F/ '{print $4}')
  repo=$(echo "$url" | awk -F/ '{print $5}' | sed 's/.git//g')
  echo "User: $user    Repo: $repo"
done