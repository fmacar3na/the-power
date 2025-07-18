.  ./.gh-api-examples.conf

# https://docs.github.com/en/enterprise-cloud@latest/rest/apps/apps?apiVersion=2022-11-28#list-installations-for-the-authenticated-app
# GET /app/installations

# This endpoint has to be presented with a jwt
# If the script is passed an argument $1 use that as the JWT
if [ -z "$1" ]
  then
    JWT=$(./tiny-call-get-jwt.sh 2>/dev/null)
  else
    JWT=$1
fi

page=1
per_page=100
all_results="[]"

while :; do
  response=$(curl -s ${curl_custom_flags} \
    -H "Authorization: Bearer ${JWT}" \
    "${GITHUB_API_BASE_URL}/app/installations?per_page=${per_page}&page=${page}")
  # Skip page if error message is present
  if [[ "$response" =~ ^\{ ]]; then
    error_message=$(echo "$response" | jq -r '.message // empty')
  else
    error_message=""
  fi
  if [ "$error_message" = "Unable to complete request that contains suffixed values in the response payloads." ]; then
    echo "Skipping page $page due to error: $error_message" >&2
    page=$((page + 1))
    continue
  fi
  count=$(echo "$response" | jq 'length')
  all_results=$(printf '%s\n%s\n' "$all_results" "$response" | jq -s 'add')
  if [ "$count" -lt "$per_page" ]; then
    break
  fi
  page=$((page + 1))
done

echo "$all_results"
