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

# Parse the first and second directories, and hostname of each URL
echo "\n\nList of User, Repo Names, and Hostnames: "
for url in "${repo_urls[@]}"; do
  # Remove the protocol from the URL (e.g., "https://")
  url=$(echo "$url" | sed -E 's/^https?:\/\///')

  # Extract the first and second directories
  user=$(echo "$url" | cut -d '/' -f 1)
  repo=$(echo "$url" | cut -d '/' -f 2 | sed -E 's/\.git$//')

  # Extract the hostname
  hostname=$(echo "$url" | cut -d '/' -f 1 | sed -E 's/^(.*)\.(.*)\.(.*)$/\1.\2/')

  # Display the user, repo names, and hostname
  echo "User: $user   Repo: $repo   Hostname: $hostname"
done