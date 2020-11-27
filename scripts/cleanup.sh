#!/bin/bash

set -e


# Delete the previously created VM:

resourceGroup=rg-ne-jupyter-notebook-$(whoami)
vmName=vm-ne-jupyter-notebook-$(whoami)

# neurocode.io
az account set -s $subscriptionId

az vm delete \
  -n $vmName \
  -g $resourceGroup \
  --yes

az group delete \
  -n $resourceGroup \
  --yes

appId=$(az ad app list --filter "displayname eq 'jupyter-notebook-ad-login'" | jq -r '.[0].appId')
az ad app delete --id $appId

az keyvault purge --name kv-ne-jupyternotebook
