#!/bin/bash
set -eu

resourceGroup=rg-ne-jupyter-notebook-$(whoami)
vmName=vm-ne-jupyter-notebook-$(whoami)

az account set -s $subscriptionId

# objectId=$(az identity create -g $resourceGroup -n $vmName-identity | jq -r '.principalId')
# # az ad sp show --id XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX --query objectId --out tsv
# az keyvault create --location northeurope --name $vmName-keyvault --resource-group $resourceGroup

# az keyvault set-policy --name $vmName-keyvault --object-id $objectId --secret-permissions get list 

vaultName=kv-ne-jupyternotebook

function create_resource_group() {
  az group create \
    -l northeurope \
    -n $resourceGroup
}

function create_keyvault() {
  export objectId=$(az identity create -g $resourceGroup -n id-$vmName | jq -r '.principalId')
  az keyvault create --location northeurope --name $vaultName --resource-group $resourceGroup --enable-soft-delete false
  az keyvault set-policy --name $vaultName --object-id $objectId --secret-permissions get list 
}


function create_ad_app() {
  az ad app create \
    --display-name jupyter-notebook-ad-login \
    --native-app \
    --required-resource-accesses "$(cat scripts/manifest.json)" \
    --reply-urls https://localhost:8443/oauth2/callback

  # Azure AD is eventual consitent ;)
  sleep 5


  export appId=$(az ad app list --filter "displayname eq 'jupyter-notebook-ad-login'" | jq -r '.[0].appId')
  export azureAdAppPassword=$(openssl rand -base64 20)

  az ad app credential reset --id $appId -p $azureAdAppPassword --years 1
}


function save_crendentials() {
  credentials=$(echo "client_secret=${azureAdAppPassword}\nclient_id=${appId}\ntenant_id=${tenantId}" | base64 -w 0)
  az keyvault secret set --name credentials --vault-name $vaultName --value $credentials
}

create_resource_group
create_keyvault
create_ad_app
save_crendentials
