#!/bin/bash
set -eu

resourceGroup=jupyter-notebook-$(whoami)
vmName=jupyter-notebook-$(whoami)

az account set -s $subscriptionId

# objectId=$(az identity create -g $resourceGroup -n $vmName-identity | jq -r '.principalId')
# # az ad sp show --id XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX --query objectId --out tsv
# az keyvault create --location northeurope --name $vmName-keyvault --resource-group $resourceGroup

# az keyvault set-policy --name $vmName-keyvault --object-id $objectId --secret-permissions get list 


function create_keyvault() {
  export objectId=$(az identity create -g $resourceGroup -n $vmName-identity | jq -r '.principalId')
  az keyvault create --location northeurope --name $vmName-keyvault --resource-group $resourceGroup
  az keyvault set-policy --name $vmName-keyvault --object-id $objectId --secret-permissions get list 
}


function create_ad_app() {
  az ad app create \
    --display-name jupyter-notebook-ad-login \
    --native-app \
    --required-resource-accesses @manifest.json \
    --reply-urls http://localhost:8080

  # Azure AD is eventual consitent ;)
  sleep 5


  export appId=$(az ad app list --filter "displayname eq 'jupyter-notebook-ad-login'" | jq -r '.[0].appId')
  export azureAdAppPassword=$(openssl rand -base64 20)

  az ad app credential reset --id $appId -p $azureAdAppPassword --years 1
}


function save_crendentials() {
  credentials=$(echo "client_secret=${azureAdAppPassword}\nclient_id=${appId}" | base64)
  az keyvault secret set --name credentials --vault-name $vmName-keyvault --value $credentials
}


