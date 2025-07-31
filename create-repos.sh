#!/bin/bash

.  ./.gh-api-examples.conf

APP_INSTALLS=$(./tiny-list-app-installations.sh)

# Iterate over each installation
echo "$APP_INSTALLS" | jq -c '.[]' | while read -r install; do
  install_id=$(echo "$install" | jq -r '.id')
  org=$(echo "$install" | jq -r '.account.login')
  if [ -z "$org" ] || [ "$org" = "null" ]; then
    continue
  fi

  echo "➡️  Creating repos for $org (install_id: $install_id)"
  GITHUB_TOKEN=$(./ent-call-get-installation-token.sh  $install_id | jq -r '.token')
  for repo_num in $(seq 1 10); do
    repo="private-repo-$repo_num"
    response=$(curl -s -w "\n%{http_code}" -X POST "$GITHUB_API_BASE_URL/orgs/$org/repos" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -d "{\"name\":\"$repo\",\"private\":true,\"auto_init\":true}")
    http_code=$(echo "$response" | tail -n1)
    json_body=$(echo "$response" | sed '$d')
    if [[ "$http_code" == "201" ]]; then
      echo "   ✅ Created $org/$repo"
    else
      echo "   ❌ Failed to create $org/$repo (HTTP $http_code)"
      #echo "   Response: $json_body"
    fi
  done
done

echo "🎉 Done creating repositories."
