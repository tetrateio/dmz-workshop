#!/usr/bin/env bash

: ${KEYCLOACK_PWD?"Need to set KEYCLOACK_PWD environment variable"}

export TOKEN=$(curl --location --request POST 'https://keycloak.demo.zwickey.net/auth/realms/master/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'username=admin' \
--data-urlencode 'password=t3trat3!' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'client_id=admin-cli' | jq -r '.access_token')
echo token: $TOKEN

declare -a arr=("foxy" "have" "mill" "book" "lean" "dorm" "pool" "cane" "rack" "date" "timmers"
                "wear" "deer" "bean" "duck" "year" "loan" "pray" "bulb" "jump" "sick" "adam"
                "pity" "spin" "cook" "pump" "dawn" "rush" "term" "axis" "loss" "line"
                "rank" "thin" "wage" "folk" "gear" "fade" "pace" "bike" "grip" "slap" "fool" "foo"
                )

# Declare a string array
USER_GUIDS=()

for i in "${arr[@]}"
do
   echo "User: $i"
   export USER=$i
   curl https://keycloak.demo.zwickey.net/auth/admin/realms/tetrate/users \
   -H "Content-Type: application/json" \
   -H "Authorization: bearer $TOKEN"  \
   --data '{"firstName":"'$i'","lastName":"'$i'", "username":"'$i'","email":"'$i'@tetrate.io", "enabled":"true","credentials":[{"type":"password","value":"t3trat3!","temporary":false}]}'

   # Get the UID
   export USER_GUID=$(curl https://keycloak.demo.zwickey.net/auth/admin/realms/tetrate/users?username=$i \
     -H "Content-Type: application/json" \
     -H "Authorization: bearer $TOKEN" | jq -r '.[0].id')
   echo UID: $USER_GUID
   USER_GUIDS+=("$USER_GUID")
   envsubst < helpers/user.yaml | tctl apply -f - 
done

for value in "${USER_GUIDS[@]}"
do
     echo "- user: organizations/tetrate/users/$value"
done