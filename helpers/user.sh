#!/usr/bin/env bash

: ${KEYCLOACK_PWD?"Need to set KEYCLOACK_PWD environment variable"}

function getToken() {
TOKEN=$(curl --silent --location --request POST 'https://keycloak.demo.zwickey.net/auth/realms/master/protocol/openid-connect/token' \
      --header 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode 'username=admin' \
      --data-urlencode 'password=t3trat3!' \
      --data-urlencode 'grant_type=password' \
      --data-urlencode 'client_id=admin-cli' | jq -r '.access_token')
   echo ${TOKEN}

}

function createKeycloakUser() {
   user=$1 
   curl --silent https://keycloak.demo.zwickey.net/auth/admin/realms/tetrate/users \
   -H "Content-Type: application/json" \
   -H "Authorization: bearer "$(getToken) \
   --data '{"firstName":"'$user'","lastName":"'$user'", "username":"'$user'","email":"'$user'@tetrate.io", "enabled":"true","credentials":[{"type":"password","value":"t3trat3!","temporary":false}]}' 
}
function getKeycloakUser() {
   user=$1 	
   GUID=$(curl --silent https://keycloak.demo.zwickey.net/auth/admin/realms/tetrate/users?username=$user \
   -H "Content-Type: application/json" \
   -H "Authorization: bearer "$(getToken) | jq -r '.[0].id')
   echo ${GUID}
}

declare -a arr=("foxy" "have" "mill" "book" "lean" "dorm" "pool" "cane" "rack" "date" "timmers"
                "wear" "deer" "bean" "duck" "year" "loan" "pray" "bulb" "jump" "sick" "adam"
                "pity" "spin" "cook" "pump" "dawn" "rush" "term" "axis" "loss" "line"
                "rank" "thin" "wage" "folk" "gear" "fade" "pace" "bike" "grip" "slap" "fool" "foo"
		"dude" "pork" )

# Declare a string array
USER_GUIDS=()

for i in "${arr[@]}"
do
   export USER=$i
   USER_CREATED=$(createKeycloakUser $i)
   USER_GUID=$(getKeycloakUser $i)

   # Get the UID
   echo UID: $USER_GUID $i
   USER_GUIDS+=("$USER_GUID")
   envsubst < helpers/user.yaml | tctl apply -f - 
done

for value in "${USER_GUIDS[@]}"
do
     echo "- user: organizations/tetrate/users/$value"
done
