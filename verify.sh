#!/bin/bash
set -eu


ensure_variable() {
  if [[ -n "$2" ]]
    then
      echo "variable OK"
    else
      echo "Missing env variable ${1}"
      exit 1
  fi
}

ensure_variable "subscriptionId" $subscriptionId
ensure_variable "spotInstance" $spotInstance
ensure_variable "vmAdminPassword" $vmAdminPassword
ensure_variable "vmSize" $vmSize
ensure_variable "tenantId" $tenantId
