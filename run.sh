#!/bin/bash

set -eu

if ! command -v docker &> /dev/null
then
    echo "docker missing? Shouldnt happen..."
    exit 1
fi

docker run --rm -d --net=host donchev7/jupyter-cuda-torch:6.5.1

docker run --net=host --rm --init -d quay.io/oauth2-proxy/oauth2-proxy:v6.1.1 \
    --client-id ${client_id} \
    --client-secret ${client_secret} \
    --cookie-secret $(openssl rand -hex 16) \
    --provider \
    oidc \
    --provider-display-name \
    Microsoft Azure AD \
    --redirect-url \
    https://kibana.private.${env}.azure.vaillant-group.com/oauth2/callback \
    --email-domain \
    '*' \
    --oidc-issuer-url \
    https://login.microsoftonline.com/${tenantId}/v2.0 \
    --http-address \
    0.0.0.0:8080 \
    --upstream \
    http://localhost:8888
