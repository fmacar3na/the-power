#!/bin/bash

.  ./.gh-api-examples.conf

# https://docs.github.com/en/enterprise-cloud@latest/rest/enterprise-admin/organization-installations?apiVersion=2022-11-28#uninstall-a-github-app-from-an-enterprise-owned-organization
# DELETE /enterprises/{enterprise}/apps/organizations/{org}/installations/{installation_id}

APP_INSTALLS=$(./tiny-list-app-installations.sh)

# Iterate over each installation
echo "$APP_INSTALLS" | jq -c '.[]' | while read -r install; do
  install_id=$(echo "$install" | jq -r '.id')
  org=$(echo "$install" | jq -r '.account.login')
  if [ -z "$org" ] || [ "$org" = "null" ]; then
    continue
  fi

  GITHUB_TOKEN=$(./ent-call-get-installation-token.sh  $install_id | jq -r '.token')
  echo "➡️  Uninstalling app for $org"
  response=$(curl -s -w "\n%{http_code}" \
    -X DELETE \
    -H "X-GitHub-Api-Version: ${github_api_version}" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "${GITHUB_API_BASE_URL}/enterprises/${enterprise}/apps/organizations/${org}/installations/${install_id}")
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')
  if [[ "$http_code" -lt 300 ]]; then
    echo "   ✅ Uninstalled on $org (HTTP $http_code)"
  else
    echo "   ❌ Failed to uninstall on $org (HTTP $http_code)"
    #echo "   Response: $json_body"
  fi
done

echo "🎉 Done uninstalling app on all organizations."
