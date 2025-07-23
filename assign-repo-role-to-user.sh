#!/bin/bash

.  ./.gh-api-examples.conf

# https://docs.github.com/en/rest/collaborators/collaborators?apiVersion=2022-11-28#add-a-repository-collaborator

APP_INSTALLS=$(./tiny-list-app-installations.sh)
user="guperrot_tntmd2"
repo="private-repo-1"

# Iterate over each installation
echo "$APP_INSTALLS" | jq -c '.[]' | while read -r install; do
  install_id=$(echo "$install" | jq -r '.id')
  org=$(echo "$install" | jq -r '.account.login')
  if [ -z "$org" ] || [ "$org" = "null" ]; then
    continue
  fi

  echo "➡️   Assigning repo permissions for $org (install_id: $install_id)"
  GITHUB_TOKEN=$(./ent-call-get-installation-token.sh  $install_id | jq -r '.token')
  response=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -d "{\"permission\":\"triage\"}" \
  "$GITHUB_API_BASE_URL/repos/$org/$repo/collaborators/$user")
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')
  if [[ "$http_code" == "201" ]]; then
    echo "   ✅ Repo permissions assigned to $user"
  else
    echo "   ❌ Failed to assign repo permissions (HTTP $http_code)"
    #echo "   Response: $json_body"
  fi
done

echo "🎉 Done assigning repo permissions."
