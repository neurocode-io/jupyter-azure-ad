#!/bin/bash

set -eu

resourceGroup=jupyter-notebook-$(whoami)
vmName=jupyter-notebook-$(whoami)

function create_resource_group() {
  az group create \
    -l northeurope \
    -n $resourceGroup
}

function create_nsg() {
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
}


function create_vm() {
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
}


function add_extensions() {
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


  # Install azure CLI:
  az vm extension set \
    --resource-group $resourceGroup \
    --vm-name $vmName \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --settings '{"fileUris": ["https://gist.githubusercontent.com/donchev7/6c019b9461c0a3acac3f5d998929fd74/raw/e0eddb1ffb8ba61151c5e461b8fa547324bc4847/ubuntu-install-az.sh"], "commandToExecute": "./ubuntu-install-az.sh"}'

  # Print the status:

  az vm get-instance-view \
      --resource-group $resourceGroup \
      --name $vmName \
      --query "instanceView.extensions"
}

