#!/bin/bash

set -e

resourceGroup=ne-icelandic-model-$(whoami)
vmName=ne-icelandic-model-$(whoami)

# neurocode.io
az account set -s e9a0397c-9b68-49ea-ae88-dcbd2f08e73e

az group create \
  -l northeurope \
  -n $resourceGroup

az network nsg create \
  -g $resourceGroup \
  -n $vmName-nsg


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

az vm create \
  -n $vmName \
  -g $resourceGroup \
  --image UbuntuLTS \
  --size Standard_B1S \
  --vnet-name ne-network-first-16 \
  --nsg $vmName-nsg \
  --subnet ne-subnet-first-24 \
  --admin-username azureuser \
  --admin-password $(openssl rand -base64 20) \
  --authentication-type password
  # --priority Spot \
  # --eviction-policy Deallocate \
  # --max-price -1 \


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
