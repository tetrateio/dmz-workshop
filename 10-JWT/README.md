# Overview

In the previous Security lab, we focused on perimeter security and configured policies to restrict access based on the Workspace.
In this lab we will secure the public ingress and enforce user authentication so that only properly authenticated users that have the
right permissions can use the application.

We will configure Authentication and Authorization settings to enforce this.

## Export the user ID that will be used in access policies

In the different access policies we'll be applying, we will be enforcing a particular Subject in the JWT token. The Identity Provider generates tokens with the UUID of the user in the `sub` claim, so before starting this lab, let's make sure we have the right value for our user exported in the `$TCTL_USERID` environment variable:

```bash
source 10-JWT/set-userid.sh
```

## Configuring User AuthN/Z for Secure App(s)

Our application ingress for the secure applications does not contain any policy for user authentication or authorization (AuthN/Z).  Within TSB establishing this policy is an easy task.  First, ensure you have set an environment variable in the shell you are using named `PREFIX`.  You will also want to ensure that your `tctl` CLI is targeted and logged into the TSB management plane.

1.  Configure the `IngressGateway` for `secure.public.$PREFIX.cloud.zwickey.net` with `authentication` and `authorization` settings to enforce JWT validation and rules based on the token claims using `tctl apply`:

```bash
envsubst < 10-JWT/01-tsb-cloud-west-jwt.yaml | tctl apply -f -   
``` 

Inspect the file `10-JWT/01-tsb-cloud-west-jwt`.  The important pieces are in the `authentication` and `authorization` sections:

```yaml
authentication:
  jwt:
    issuer: "https://keycloak.demo.zwickey.net/auth/realms/tetrate"
    jwksUri: "https://keycloak.demo.zwickey.net/auth/realms/tetrate/protocol/openid-connect/certs"
authorization:
  local:
    rules:
      - name: only-$PREFIX
        from:
          - jwt:
              sub: "$TCTL_USERID"
              iss: "https://keycloak.demo.zwickey.net/auth/realms/tetrate"
        to:
          - paths: ["*"]
```

In the `authentication` section we are configuring how JWT tokens are going to be validated. There we configure the issuer for the tokens and the keystore with the keys to be used to validate the token signature.

In the `authorization` section we configure the AuthZ rules we want to apply to incoming traffic. In this example we will:

* Enforce the configured rule for all requests (`paths: ["*"]`).
* Require tokens to be issued by the configured issuer.
* Require the `sub` claim in the token to have the value of `$TCTL_USERID`.

Changes may take some seconds to propagate. Once they are propagated you can check the `AuthorizationPolicy` that has been generated for the secure ingress with:

```bash
kubectl --context public-west -n $PREFIX-demo-secure get authorizationpolicy secure-gateway-mesh-external -o yaml
```

You will get back the policy with the following rule for your `$PREFIX`:

```yaml
rules:
- from:
  - source:
      requestPrincipals:
      - https://keycloak.demo.zwickey.net/auth/realms/tetrate/b635c4c6-f620-4846-9501-dfe554f6b4c5
to:
- operation:
    hosts:
    - secure.public.nacx.cloud.zwickey.net
    - secure.public.nacx.cloud.zwickey.net:8443
    paths:
    - '*'
    ports:
    - "8443"
when: []
```

What this means is that any incoming request needs to match the rule; otherwise traffic will be rejected. Let's try it. Open the browser and navigate to `https://secure.public.$PREFIX.cloud.zwickey.net/`. You should see the following error (if you don't see it try refreshing the page to make sure it is not being served by the browser cache):
```
RBAC: access denied
```

## Obtain a JWT token and access the Secure App again

Let's get a token for your current user from the Identity Provider (Keycloak):

```bash
source 10-JWT/get-token.sh
```

This script will request a Bearer Access Token to the Identity Provider and print the JWT token as well as the decoded claims. Note that it will already export the token in the `$JWT_TOKEN` environment variable.

```bash
JWT_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJRT3VTQUpUa3VEaG5wRllqSmhDNG1UZUxfR0xHN3dFWEVOcDhuVGt0YnlJIn0.eyJleHAiOjE2MzIzODgyMzgsImlhdCI6MTYzMjM4NzkzOCwianRpIjoiYTFkNDI0YzEtNWMyOC00MjRkLTg3ZjctMTQ2N2M0YjgwZGEzIiwiaXNzIjoiaHR0cHM6Ly9rZXljbG9hay5kZW1vLnp3aWNrZXkubmV0L2F1dGgvcmVhbG1zL3RldHJhdGUiLCJzdWIiOiJiNjM1YzRjNi1mNjIwLTQ4NDYtOTUwMS1kZmU1NTRmNmI0YzUiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJhY2NvdW50LXRva2VuIiwic2Vzc2lvbl9zdGF0ZSI6IjMxNWI3N2M2LTZmZDAtNDRhOS05MGMwLWExOGNjNTgxOTJlYyIsImFjciI6IjEiLCJzY29wZSI6InByb2ZpbGUgZW1haWwiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsIm5hbWUiOiJuYWN4IG5hY3giLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJuYWN4IiwiZ2l2ZW5fbmFtZSI6Im5hY3giLCJmYW1pbHlfbmFtZSI6Im5hY3giLCJlbWFpbCI6Im5hY3hAdGV0cmF0ZS5pbyJ9.bwnmurYd_VZLhyW4k7xnhl_9Ed5FdP2Qd7yB9aMiHkSqiPjWPvNgYjfFshw9XA7g1xd1_s2MIKEYG45_HOLJRUbRIO_O3qyPpYPckSACNpEtpV4HWDcLISOOz6MC9XWCVh2lMYmh6ZX6Nw_CwF21G7PBMiWMUo8FHpZL_lR0MP5fhKN2dfPizxIEHFer6FOSFkdHnWQk0D3FgFyUDRzTE0NFrfbDgWFhrUrGfULwrdAqiiDiGPrmEt0f4Ewvx3XtQjX8clK3gO47_dUy54mudRgrtKKPvg5JMWTIpDC-ZpvfUnvAQXz7dh39opOPEIK9omT7dNhLRHNlXbx0WqC60g
{
  "exp": 1632388238,
  "iat": 1632387938,
  "jti": "a1d424c1-5c28-424d-87f7-1467c4b80da3",
  "iss": "https://keycloak.demo.zwickey.net/auth/realms/tetrate",
  "sub": "b635c4c6-f620-4846-9501-dfe554f6b4c5",
  "typ": "Bearer",
  "azp": "account-token",
  "session_state": "315b77c6-6fd0-44a9-90c0-a18cc58192ec",
  "acr": "1",
  "scope": "profile email",
  "email_verified": false,
  "name": "nacx nacx",
  "preferred_username": "nacx",
  "given_name": "nacx",
  "family_name": "nacx",
  "email": "nacx@tetrate.io"
}
```

Now you can try access the Secure application again, by sending the `$JWT_TOKEN` in the Authorization header. We can do this with a `curl` command:

```bash
curl -k https://secure.public.${PREFIX}.cloud.zwickey.net -H "Authorization: Bearer ${JWT_TOKEN}"
```

You will see the HTML contents of the Secure App frontend. If instead you see a `token expired` error, you can run again the `source 10-JWT/get-token.sh` to get a new token.

## Enforcing access with additional claims

Now we have seen how the user has been validated, let's see how we can enforce additional constraints based on token claims.

### Checking what happens when additional claims are not met

We will apply a policy that requires the token to contain a `group: admins` claim. The tokens issued for our user do not contain that claim, so access should be denied after applying the policy.

```bash
envsubst < 10-JWT/02-tsb-cloud-west-jwt-claims-fail.yaml | tctl apply -f -   
```

The important part of the new policy is the following:

```yaml
rules:
- name: only-$PREFIX
    from:
    - jwt:
        sub: "$TCTL_USERID"
        iss: "https://keycloak.demo.zwickey.net/auth/realms/tetrate"
        other:
          group: admins
    to:
    - paths: ["*"]
```

Note the presence of the `other` element. It allows setting other claims to be required in the JWT tokens that are not necessarily well-known JWT claims.

Wait a few seconds until the changes to the policy have propagated, and inspect the contents of the policy again:

```bash
kubectl --context public-west -n $PREFIX-demo-secure get authorizationpolicy secure-gateway-mesh-external -o yaml
```

You will see the JWT rule has a new condition that will enforce the presence of the configured claim for all incoming requests.

```yaml
when:
- key: request.auth.claims[group]
  values:
  - admins
```

Let's try accessing the app again:

```bash
curl -k https://secure.public.${PREFIX}.cloud.zwickey.net -H "Authorization: Bearer ${JWT_TOKEN}"
```

We should see again the access denied error:
```
RBAC: access denied
```

### Configuring additional claims present in the JWT token

Now let's configure a policy with a claim that actually exists in the token, such as the `preferred_user` one:

```bash
envsubst < 10-JWT/03-tsb-cloud-west-jwt-claims-ok.yaml | tctl apply -f -   
```

Wait a few seconds until the changes to the policy have propagated, and inspect the contents of the policy again:

```bash
kubectl --context public-west -n $PREFIX-demo-secure get authorizationpolicy secure-gateway-mesh-external -o yaml
```

You will see the JWT rule has a new condition that will enforce the presence of the configured claim for all incoming requests.

```yaml
when:
- key: request.auth.claims[preferred_username]
  values:
  - $PREFIX
```

Let's try accessing the app again:

```bash
curl -k https://secure.public.${PREFIX}.cloud.zwickey.net -H "Authorization: Bearer ${JWT_TOKEN}"
```

You will see again the HTML contents of the Secure App frontend.


## Cleanup

Finally, let's remove the JWT policy to leave the Secure App endpoint accessible for other Labs:

```bash
envsubst < 10-JWT/04-tsb-cloud-west-jwt-reset.yaml | tctl apply -f -   
```

Wait a bit for the policy to take effect and verify no JWT restrictions apply anymore by opening the Secure App in the browser: `https://secure.public.$PREFIX.cloud.zwickey.net/`.
