#!/bin/bash

set -e

if ! command -v docker &> /dev/null
then
    echo "docker missing? Shouldnt happen..."
    exit
fi

docker run --rm -d --net=host donchev7/jupyter-cuda-torch:6.5.1

docker run --net=host --rm --init -d quay.io/oauth2-proxy/oauth2-proxy:v6.1.1 --client-id '************************' \
    --client-secret '*************************' \
    --cookie-secret $(openssl rand -hex 16) \
    --provider \
    oidc \
    --provider-display-name \
    Microsoft Azure AD \
    --client-id \
    6dfb45a2-9c98-466d-822f-b0d8c33811bc \
    --redirect-url \
    https://kibana.private.${env}.azure.vaillant-group.com/oauth2/callback \
    --email-domain \
    '*' \
    --oidc-issuer-url \
    https://login.microsoftonline.com/67e4db54-80ae-4739-b54d-5ee94bd6472e/v2.0 \
    --http-address \
    0.0.0.0:8080 \
    --upstream \
    http://localhost:8888

