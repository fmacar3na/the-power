#!/bin/bash

.  ./.gh-api-examples.conf

if [ -n "$1" ]; then
  org_max_suffix=$1
fi

usernames=$(./list-enterprise-team-members.sh "$team")
app_installs=$(./tiny-list-app-installations.sh)

# Iterate over each installation
echo "$app_installs" | jq -c '.[]' | while read -r install; do
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

  echo "➡️  Assigning roles for $org (install_id: $install_id)"
  GITHUB_TOKEN=$(./ent-call-get-installation-token.sh $install_id | jq -r '.token')
  response=$(curl -s -w "\n%{http_code}" \
    -H "X-GitHub-Api-Version: ${github_api_version}" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${GITHUB_API_BASE_URL}/orgs/${org}/organization-roles")
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')
  if [[ "$http_code" -lt 300 ]]; then
    first_role_id=$(echo "$json_body" | jq -r '.roles[0].id')
    echo "   ➡️ Got first role id for $org: $first_role_id"
  else
    echo "   ❌ Failed to get roles for $org (HTTP $http_code)"
  fi
  
  for username in $usernames; do
    response=$(curl -s -w "\n%{http_code}" -X PUT \
      -H "X-GitHub-Api-Version: ${github_api_version}" \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${GITHUB_API_BASE_URL}/orgs/${org}/organization-roles/users/${username}/${first_role_id}")
    http_code=$(echo "$response" | tail -n1)
    json_body=$(echo "$response" | sed '$d')
    if [[ "$http_code" -lt 300 ]]; then
      echo "   ✅ Assigned role to $username in $org"
    else
      echo "   ❌ Failed to assign role to $username in $org (HTTP $http_code)"
      break
    fi
  done
done

echo "🎉 Done assigning roles."
