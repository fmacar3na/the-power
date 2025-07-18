.  ./.gh-api-examples.conf

# https://docs.github.com/en/enterprise-cloud@latest/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation
#


# rate_limits: https://docs.github.com/en/developers/apps/building-github-apps/rate-limits-for-github-apps


JWT=$(./ent-call-get-jwt.sh ${ent_app_id} 2>/dev/null)

# Allow passing installation_id as $1, fallback to ent_app_installation_id
if [ -n "$1" ]; then
  installation_id="$1"
else
  installation_id="${ent_app_installation_id}"
fi

curl --silent ${curl_custom_flags} \
     -X POST \
     -H "Authorization: Bearer ${JWT}" \
        "${GITHUB_API_BASE_URL}/app/installations/${installation_id}/access_tokens"

