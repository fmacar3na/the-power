#!/bin/bash

.  ./.gh-api-examples.conf

# get "/enterprises/:enterprise_id/teams/:team_id/memberships"
# This requires a PAT being set as an env variable as GITHUB_TOKEN as the API is not compatible with Apps yet

team_id="$1"
page=1
per_page=100
all_logins=()

while :; do
  response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${GITHUB_API_BASE_URL}/enterprises/${enterprise}/teams/${team_id}/memberships?per_page=${per_page}&page=${page}")
  http_code=$(echo "$response" | tail -n1)
  json_body=$(echo "$response" | sed '$d')
  if [[ "$http_code" -lt 300 ]]; then
    logins=( $(echo "$json_body" | jq -r '.[].login') )
    if [ ${#logins[@]} -eq 0 ]; then
      break
    fi
    all_logins+=("${logins[@]}")
    if [ ${#logins[@]} -lt $per_page ]; then
      break
    fi
    page=$((page + 1))
  else
    echo "   ❌ Failed to get enterprise team members (HTTP $http_code) $json_body"
    exit 1
  fi
done

printf "%s\n" "${all_logins[@]}"
