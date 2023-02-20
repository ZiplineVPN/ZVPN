# Set Gitea API URL and access token
GITEA_API_URL="https://git.nicknet.works/api/v1"
# Prompt for Gitea API key
read -p "Enter your Gitea API key: " GITEA_API_KEY

# Check if --real-run was provided
if [ $# -eq 0 ] || [ "$1" == "--real-run" ]; then
    real_run=1
    if [ $# -eq 0 ]; then
        real_run=0
    fi

    # Find all git repositories in the current working directory and its subdirectories
    for repo in $(find . -name ".git" -type d); do
        # Get the path to the parent directory of the git repository
        repo_path="$(dirname "$repo")"

        # Get the remote URL
        remote_url=$(git --git-dir="$repo" --work-tree="$repo_path" remote get-url origin 2>/dev/null)

        # Check if the remote URL command failed
        if [ $? -ne 0 ]; then
            echo "Error: No such remote 'origin' in $repo_path."
            continue
        fi

        echo $repo

        # Check if the remote URL is a Gitea URL
        if [[ $remote_url =~ ^(https?:\/\/)([^\/]+)\/([^\/]+)\/([^\/]+)\/?$ ]]; then
            org_name=${BASH_REMATCH[3]}
            user_name=${BASH_REMATCH[4]}

            # Check if the organization already exists in Gitea
            org_resp=$(curl --silent -H "Authorization: token $GITEA_ACCESS_TOKEN" -X GET "$GITEA_API_URL/orgs/$org_name")
            if [[ "$org_resp" == *"user redirect does not exist"* ]]; then
                # Create the organization in Gitea
                if [ $real_run -eq 1 ]; then
                    curl -H "Authorization: token $GITEA_ACCESS_TOKEN" -X POST "$GITEA_API_URL/admin/users/$user_name/orgs" -d '{"username": "'"$org_name"'"}'
                    echo "Created organization $org_name for user $user_name in $repo_path."
                else
                    echo "curl -H 'Authorization: token $GITEA_ACCESS_TOKEN' -X POST '$GITEA_API_URL/admin/users/$user_name/orgs' -d '{\"username\": \"$org_name\"}'"
                fi
            else
                echo "Organization $org_name already exists in Gitea, skipping creation."
            fi
        else
            echo "Remote URL $remote_url for $repo_path is not a Gitea URL, skipping."
        fi
    done
else
    echo "Error: Invalid argument was provided."
    echo "Usage: $0 [--real-run]"
    exit 1
fi