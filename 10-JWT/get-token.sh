#!/usr/bin/env bash

# Base64 decode an url-encoded token.
# This takes care of converting the url-encoded character as well as adding the Base64 padding
# that is omitted from JWT token fragments.
decode_base64_url() {
    local len=$((${#1} % 4))
    local result="${1}"
    if [[ ${len} -eq 2 ]]; then result="${1}"'=='
    elif [[ ${len} -eq 3 ]]; then result="${1}"'='
    fi
    echo "${result}" | tr '_-' '/+' | base64 --decode
}

TOKEN=$(curl --silent --location --request POST 'https://keycloak.demo.zwickey.net/auth/realms/tetrate/protocol/openid-connect/token' \
      --header 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode "username=$PREFIX" \
      --data-urlencode 'password=t3trat3!' \
      --data-urlencode 'grant_type=password' \
      --data-urlencode 'client_id=account-token' | jq -r '.access_token')

# JWT tokens are in the format: <header>.<payload>
# Get the payload part as it is the one that contains the expiration claim.
PAYLOAD=`echo ${TOKEN} | cut -d. -f2`
# Decode the payload to get the raw json with the claims
CLAIMS=`decode_base64_url ${PAYLOAD}`

echo "JWT_TOKEN=${TOKEN}"
echo ${CLAIMS} | jq .

export JWT_TOKEN=${TOKEN}
