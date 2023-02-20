#!/bin/bash

GITEA_API_URL="https://git.nicknet.works/api/v1"
GITEA_API_KEY=""

print_usage() {
  printf "Usage: %s [-r] [dir]\n" "$0"
  printf "  -r  Run the script\n"
  printf "  dir Directory to work on. Defaults to current directory if not provided.\n"
}

run_script=0
working_directory=$(pwd)

while getopts 'r' flag; do
  case "${flag}" in
    r) run_script=1 ;;
    *) print_usage
       exit 1 ;;
  esac
done

shift $(($OPTIND - 1))

if [[ $# -eq 1 ]]; then
  working_directory=$1
elif [[ $# -gt 1 ]]; then
  print_usage
  exit 1
fi

if [[ $run_script -eq 0 ]]; then
  print_usage
  exit 0
fi

for repo in $(find "$working_directory" -name ".git" -type d); do
  repo_path="$(dirname "$repo")"
  remote_url=$(git --git-dir="$repo" --work-tree="$repo_path" remote get-url origin 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "Error: No such remote 'origin' in $repo_path."
    continue
  fi

  echo $repo_path

  if [[ $remote_url =~ ^(https?:\/\/)([^\/]+)\/([^\/]+)\/([^\/]+)\/?$ ]]; then
    org_name=${BASH_REMATCH[3]}
    user_name=${BASH_REMATCH[4]}

    org_resp=$(curl --silent -H "Authorization: token $GITEA_API_KEY" -X GET "$GITEA_API_URL/orgs/$org_name")
    if [[ "$org_resp" == *"user redirect does not exist"* ]]; then
      if [[ $run_script -eq 1 ]]; then
        curl -H "Authorization: token $GITEA_API_KEY" -X POST "$GITEA_API_URL/admin/users/$user_name/orgs" -d '{"username": "'"$org_name"'"}'
        echo "Created organization $org_name for user $user_name in $repo_path."
      else
        echo "curl -H 'Authorization: token $GITEA_API_KEY' -X POST '$GITEA_API_URL/admin/users/$user_name/orgs' -d '{\"username\": \"$org_name\"}'"
      fi
    else
      echo "Organization $org_name already exists in Gitea, skipping creation."
    fi
  else
    echo "Remote URL $remote_url for $repo_path is not a Gitea URL, skipping."
  fi
done