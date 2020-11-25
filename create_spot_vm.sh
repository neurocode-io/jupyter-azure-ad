#!/bin/bash

set -eu

resourceGroup=jupyter-notebook-$(whoami)
vmName=jupyter-notebook-$(whoami)

# neurocode.io
az account set -s $subscriptionId

az group create \
  -l northeurope \
  -n $resourceGroup

az network nsg create \
  -g $resourceGroup \
  -n $vmName-nsg


objectId=$(az identity create -g $resourceGroup -n $vmName-identity | jq -r '.principalId')
az keyvault create --location northeurope --name $vmName-keyvault --resource-group $resourceGroup

# {
#     "clientId": "73444643-8088-4d70-9532-c3a0fdc190fz",
#     "clientSecretUrl": "https://control-westcentralus.identity.azure.net/subscriptions/<SUBSCRIPTON ID>/resourcegroups/<RESOURCE GROUP>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<myUserAssignedIdentity>/credentials?tid=5678&oid=9012&aid=73444643-8088-4d70-9532-c3a0fdc190fz",
#     "id": "/subscriptions/<SUBSCRIPTON ID>/resourcegroups/<RESOURCE GROUP>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<USER ASSIGNED IDENTITY NAME>",
#     "location": "westcentralus",
#     "name": "<USER ASSIGNED IDENTITY NAME>",
#     "principalId": "e5fdfdc1-ed84-4d48-8551-fe9fb9dedfll",
#     "resourceGroup": "<RESOURCE GROUP>",
#     "tags": {},
#     "tenantId": "733a8f0e-ec41-4e69-8ad8-971fc4b533bl",
#     "type": "Microsoft.ManagedIdentity/userAssignedIdentities"    
# }
az ad sp show --id XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX --query objectId --out tsv

az keyvault set-policy --name $vmName-keyvault --object-id $objectId --secret-permissions get list 

# Allow from everywhere on port 8080
# Azure already has a DenyAllInBound nsg-rule (Priority 65500)
az network nsg rule create \
    -g $resourceGroup \
    --nsg-name $vmName-nsg \
    -n $vmName-nsg-allow-8080-rule \
    --priority 4000 \
    --direction Inbound \
    --source-address-prefixes '*' --source-port-ranges '*' \
    --destination-address-prefixes '*' --destination-port-ranges '8080' \
    --access Allow \
    --protocol '*' \
    --description "Allow 8080 incoming"

if [ $spotInstance = true ]
then
  az vm create \
    -n $vmName \
    -g $resourceGroup \
    --image UbuntuLTS \
    --size $vmSize \
    --nsg $vmName-nsg \
    --admin-username azureuser \
    --admin-password $vmAdminPassword \
    --authentication-type password \
    --priority Spot \
    --eviction-policy Deallocate \
    --max-price -1 \
    --assign-identity $vmName-identity
else
  az vm create \
    -n $vmName \
    -g $resourceGroup \
    --image UbuntuLTS \
    --size $vmSize \
    --nsg $vmName-nsg \
    --admin-username azureuser \
    --admin-password $vmAdminPassword \
    --authentication-type password \
    --assign-identity $vmName-identity
fi

# Install docker:

az vm extension set \
  --resource-group $resourceGroup \
  --vm-name $vmName \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{"fileUris": ["https://gist.githubusercontent.com/donchev7/681ddf408d7ed643cf64bda7a67281f5/raw/9cafa7a9cdd0bd0320ecfe4a09d9455f48c2e920/docker-ubuntu.sh"], "commandToExecute": "./docker-ubuntu.sh"}'

# Install CUDA:

az vm extension set \
  --resource-group $resourceGroup \
  --vm-name $vmName \
  --name NvidiaGpuDriverLinux \
  --publisher Microsoft.HpcCompute \
  --version 1.3

# Install docker nvidia:

az vm extension set \
  --resource-group $resourceGroup \
  --vm-name $vmName \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{"fileUris": ["https://gist.githubusercontent.com/donchev7/902e8da57921a1ef63115a797fe97458/raw/8d2e7587603f3a993b8d52999d864feca4ac51b0/nvidia-docker.sh"], "commandToExecute": "./nvidia-docker.sh"}'

# Print the status:

az vm get-instance-view \
    --resource-group $resourceGroup \
    --name $vmName \
    --query "instanceView.extensions"
