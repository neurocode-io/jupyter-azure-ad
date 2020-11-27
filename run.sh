#!/bin/bash

set -eu

if ! command -v docker &> /dev/null
then
    echo "docker missing? Shouldnt happen..."
    exit 1
fi

az login --identity --allow-no-subscriptions
echo -e "$(az keyvault secret show --name credentials --vault-name kv-ne-jupyternotebook --query value -o tsv | base64 -d)" > secrets

source secrets

publicIp=$(curl -H "Metadata: true" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-08-01&format=text")
docker run --rm -d --net=host donchev7/jupyter-cuda-torch:6.5.1

docker run --net=host --rm --init -it quay.io/oauth2-proxy/oauth2-proxy:v6.1.1 \
    --client-id ${client_id} \
    --client-secret ${client_secret} \
    --cookie-secret $(openssl rand -hex 16) \
    --provider \
    oidc \
    --provider-display-name \
    Microsoft Azure AD \
    --redirect-url \
    http://${publicIp}:8080/oauth2/callback \
    --email-domain \
    '*' \
    --oidc-issuer-url \
    https://login.microsoftonline.com/${tenant_id}/v2.0 \
    --http-address \
    0.0.0.0:8080 \
    --upstream \
    http://localhost:8888
