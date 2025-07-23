#!/bin/bash
# This script won't work without updates to the Orgs API to support BTs.

.  ./.gh-api-examples.conf

# https://docs.github.com/en/rest/orgs/organization-roles?apiVersion=2022-11-28#assign-an-organization-role-to-a-team

APP_INSTALLS=$(./tiny-list-app-installations.sh)
team_slug="testing"
role_id=138

# Iterate over each installation
echo "$APP_INSTALLS" | jq -c '.[]' | while read -r install; do
  install_id=$(echo "$install" | jq -r '.id')
  org=$(echo "$install" | jq -r '.account.login')
  if [ -z "$org" ] || [ "$org" = "null" ]; then
    continue
  fi

  echo "➡️   Assigning Security Manager role for $org (install_id: $install_id)"
  GITHUB_TOKEN=$(./ent-call-get-installation-token.sh  $install_id | jq -r '.token')
  response=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "$GITHUB_API_BASE_URL/orgs/$org/organization-roles/teams/$team_slug/$role_id")
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')
  if [[ "$http_code" == "204" ]]; then
    echo "   ✅ Security manager role assigned to $team_slug"
  else
    echo "   ❌ Failed to assign security manager role (HTTP $http_code)"
    #echo "   Response: $json_body"
  fi
done

echo "🎉 Done assigning security manager role."
