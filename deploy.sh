#!/bin/bash

for i in "$@"; do
    case $i in
        --azureSubscriptionId=*)
        AZURE_SUBSCRIPTION_ID="${i#*=}"
        shift
        ;;
        --azureUsername=*)
        AZURE_USERNAME="${i#*=}"
        shift
        ;;
        --azurePassword=*)
        AZURE_PASSWORD="${i#*=}"
        shift
        ;;
        --azureResourceGroupName=*)
        AZURE_RESOURCE_GROUP_NAME="${i#*=}"
        shift
        ;;
        --azureArmClientId=*)
        AZURE_ARM_CLIENT_ID="${i#*=}"
        shift
        ;;
        --azureArmClientSecret=*)
        AZURE_ARM_CLIENT_SECRET="${i#*=}"
        shift
        ;;
        --azureArmTenantId=*)
        AZURE_ARM_TENANT_ID="${i#*=}"
        shift
        ;;
        --azureStorageAccountName=*)
        AZURE_STORAGE_ACCOUNT_NAME="${i#*=}"
        shift
        ;;
        --azureStorageAccountKey=*)
        AZURE_STORAGE_ACCOUNT_KEY="${i#*=}"
        shift
        ;;
        --registry=*)
        REGISTRY="${i#*=}"
        shift
        ;;
        --registryUsername=*)
        REGISTRY_USERNAME="${i#*=}"
        shift
        ;;
        --registryPassword=*)
        REGISTRY_PASSWORD="${i#*=}"
        shift
        ;;
        --registryImageName=*)
        REGISTRY_IMAGE_NAME="${i#*=}"
        shift
        ;;
        --vstsAccount=*)
        VSTS_ACCOUNT="${i#*=}"
        shift
        ;;
        --vstsToken=*)
        VSTS_TOKEN="${i#*=}"
        shift
        ;;
        --agentUsername=*)
        AGENT_USERNAME="${i#*=}"
        shift
        ;;
        --agentPassword=*)
        AGENT_PASSWORD="${i#*=}"
        shift
        ;;
    esac
    shift
done

# az login
az login --username=$AZURE_USERNAME --password=$AZURE_PASSWORD
az account set --subscription=$AZURE_SUBSCRIPTION_ID

# get resource group location
LOCATION="eastus"

# get sshkey
SSH_KEY=$(<"$HOME/.ssh/id_rsa.pub")

IMAGE_FQDN="${REGISTRY}/${REGISTRY_IMAGE_NAME}:latest"

# assign terraform variables
export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
export TF_VAR_resource_group_name=$AZURE_RESOURCE_GROUP_NAME
export TF_VAR_location=$LOCATION

export ARM_CLIENT_ID=$AZURE_ARM_CLIENT_ID
export ARM_CLIENT_SECRET=$AZURE_ARM_CLIENT_SECRET
export ARM_TENANT_ID=$AZURE_ARM_TENANT_ID

export TF_VAR_image_registry_server=$REGISTRY
export TF_VAR_image_registry_username=$REGISTRY_USERNAME
export TF_VAR_image_registry_password=$REGISTRY_PASSWORD
export TF_VAR_image_registry_image=$IMAGE_FQDN

# TODO: -- validate this loads the key properly
export TF_VAR_ssh_key=$SSH_KEY
export TF_VAR_vsts_account=$VSTS_ACCOUNT
export TF_VAR_vsts_token=$VSTS_TOKEN

export TF_VAR_admin_username=$AGENT_USERNAME
export TF_VAR_admin_password=$AGENT_PASSWORD

# init terraform backend
cd terraform/azure

terraform init -backend-config="storage_account_name=$AZURE_STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=tfstate" \
    -backend-config="access_key=$AZURE_STORAGE_ACCOUNT_KEY" \
    -backend-config="key=buildagent.vsts.tfstate" 

# run plan
terraform plan -out run.plan
terraform apply run.plan