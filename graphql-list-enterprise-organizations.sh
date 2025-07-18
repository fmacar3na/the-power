.  ./.gh-api-examples.conf

orgs=()
after_cursor=""

while :; do

  if [ -z "$after_cursor" ]; then
    after_clause=""
  else
    after_clause=", after: \"$after_cursor\""
  fi

  # Name can be different than login and cause issues if different, but on staffship we have an error if we query login...
  read -r -d '' graphql_script <<- EOF
  {
    enterprise(slug: "$enterprise") {
      organizations(first: 1, after: "$after_cursor") {
        nodes {
          name
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
EOF

  response=$(jq -n --arg q "$graphql_script" '{query: $q}' | \
    curl -s ${curl_custom_flags} \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${GITHUB_APIV4_BASE_URL}" -d @-)

  # Extract org logins and append to orgs array
  orgs=( $(echo "$response" | jq -r '.data.enterprise.organizations.nodes[].name') )
  printf "%s\n" "${orgs[@]}"

  # Get pagination info
  has_next=$(echo "$response" | jq -r '.data.enterprise.organizations.pageInfo.hasNextPage')
  after_cursor=$(echo "$response" | jq -r '.data.enterprise.organizations.pageInfo.endCursor')

  if [ "$has_next" != "true" ]; then
    break
  fi
done

