#!/bin/bash

.  ./.gh-api-examples.conf

repository_selection="all"

json_file=/tmp/install-a-github-app-on-an-enterprise-owned-organization.json
jq -n \
           --arg client_id "${ent_app_client_id}" \
           --arg repository_selection "${repository_selection}" \
           '{
             client_id : $client_id,
             repository_selection : $repository_selection,
           }' > ${json_file}

GITHUB_TOKEN=$(./ent-call-get-installation-token.sh | jq -r '.token')

orgs=( $(./graphql-list-enterprise-organizations.sh) )

for org in "${orgs[@]}"; do
  echo "➡️  Installing app for $org"
  response=$(curl -s -w "\n%{http_code}" \
     -H "X-GitHub-Api-Version: ${github_api_version}" \
     -H "Accept: application/vnd.github.v3+json" \
     -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "${GITHUB_API_BASE_URL}/enterprises/${enterprise}/apps/organizations/${org}/installations"  --data @${json_file})
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')
  if [[ "$http_code" -lt 300 ]]; then
    echo "   ✅ Installed on $org (HTTP $http_code)"
  else
    echo "   ❌ Failed to install on $org (HTTP $http_code)"
    echo "   Response: $json_body"
  fi
done

echo "🎉 Done installing app on all organizations."