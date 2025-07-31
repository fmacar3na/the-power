#!/bin/bash

.  ./.gh-api-examples.conf

# https://docs.github.com/en/rest/teams/teams?apiVersion=2022-11-28#add-or-update-team-repository-permissions

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is not set, please provide a PAT with admin:enterprise scope."
  exit 1
fi

if [ -n "$1" ]; then
  org_max_suffix=$1
fi

APP_INSTALLS=$(./tiny-list-app-installations.sh)
repo="private-repo-2"

# Iterate over each installation
echo "$APP_INSTALLS" | jq -c '.[]' | while read -r install; do
  install_id=$(echo "$install" | jq -r '.id')
  org=$(echo "$install" | jq -r '.account.login')
  if [ -z "$org" ] || [ "$org" = "null" ]; then
    continue
  fi

  # Only process orgs with suffix less than passed suffix
  if [ -n "$org_max_suffix" ]; then
    org_suffix=$(echo "$org" | sed "s/^batch-org-//")
    if ! [[ "$org_suffix" =~ ^[0-9]+$ ]]; then
      continue
    fi
    if [[ "$org_suffix" > "$org_max_suffix" ]]; then
      continue
    fi
  fi

  echo "➡️   Assigning repo permissions for $org (install_id: $install_id)"
  GITHUB_TOKEN=$(./ent-call-get-installation-token.sh  $install_id | jq -r '.token')

  response=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -d "{\"permission\":\"triage\"}" \
  "$GITHUB_API_BASE_URL/orgs/$org/teams/$team/repos/$org/$repo")
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "201" ]] || [[ "$http_code" == "204" ]]; then
    echo "   ✅ Repo permissions assigned to $team"
  else
    echo "   ❌ Failed to assign repo permissions (HTTP $http_code) for $team"
    echo "   Response: $json_body"
  fi
  wait
done

echo "🎉 Done assigning repo permissions."
