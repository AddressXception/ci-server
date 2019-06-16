# Docker in Docker Build Server

This repository builds a generic CI server that is deployed as a docker container.

it is designed to be executed on a host machine or VM that passes the host machine's docker.sock into the container so that the image can build docker containers.

It can be deployed locally or to public or private clouds.

It includes a configuration for building a VSTS/Azure DevOps build agent.

It includes a demonstration of delpoying the VSTS agent to Azure using Terraform.

## Run Locally

### Build the Container

`./build.sh`

### Run the Agent Image

Running the image requires you to have an Azure Devops Instance configured with an agent pool named `private-ubuntu-1804` and a personal access token with read/write access to the pool.

``` bash
export BUILD_AGENT_NAME='vsts-build-agent'
export VSTS_ACCOUNT='your-vsts-account-subdomain'
export VSTS_TOKEN='your_pat_secret_key_value'
```

``` bash
docker run \
  -e VSTS_ACCOUNT=$VSTS_ACCOUNT \
  -e VSTS_TOKEN=$VSTS_TOKEN \
  -e VSTS_AGENT=vsts-agent-ubuntu-1804 \
  -e VSTS_POOL=private-ubuntu-1804 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name vsts-agent-ubuntu-1804 \
  -it $BUILD_AGENT_NAME
```

## Run the agent in the cloud

These steps will configure an Azure Resource group and will deploy the agent to the resource group.

### Prereqs

- Linux, OSX, or Windows Subsystem for Linux
- [Azure CLI Installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Docker Installed](https://www.docker.com/)
- [Terraform Installed](https://www.terraform.io/)

- The following Azure Resources
  - a service principal for Terraform to log in
  - a resource group to hold the components
  - a storage account to store terraform state.
  - (optionally) a container registry to push images to

### Configuring Prereqs

Follow these steps to configure the Azure Prerequsites

log in

``` bash
az login --username $AZURE_USERNAME --password $AZURE_PASSWORD
```

set account

``` bash
az account set --subscription $AZURE_SUBSCRIPTION_ID
```

Create a Service Principal for Terraform

``` bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$AZURE_SUBSCRIPTION_ID"
```

Outputs something like:

``` json
{
  "appId": "some-guid-value-here-abc123def",
  "displayName": "azure-cli-2018-06-15-13-49-51",
  "name": "http://azure-cli-2018-06-15-13-49-51",
  "password": "some-guid-value-here-abc123def",
  "tenant": "some-guid-value-here-abc123def"
}
```

Make note of the `appId`, `password` and `tenant` as we'll use them when deploying the resources

``` bash
export AZURE_ARM_CLIENT_ID='appId_from_above'
export AZURE_ARM_CLIENT_SECRET='password_from_above'
export AZURE_ARM_TENANT_ID='tenant_from_above'

```

Create a Resource Group (if you don't already have one you want to use)

``` bash
az group create -l $LOCATION -n $AZURE_RESOURCE_GROUP_NAME
```

Create a storage account for Terraform to store it's state

``` bash
az storage account create --resource-group=$AZURE_RESOURCE_GROUP_NAME --name=$TF_STORAGE_ACCOUNT_NAME --sku=Standard_LRS --kind=StorageV2
```

Get the credentials to log into the stoage account

``` bash
az storage account keys list --account-name=$TF_STORAGE_ACCOUNT_NAME
```

Outputs something like:

``` json
[
  {
    "keyName": "key1",
    "permissions": "Full",
    "value": "some/long/token=="
  },
  {
    "keyName": "key2",
    "permissions": "Full",
    "value": "some/long/token=="
  }
]
```

Make note of the `token value`

``` bash
export TF_STORAGE_ACCT_TOKEN='value_from_above'
```

Create a storage container to store terraform state

``` bash
az storage container create --name=tfstate --account-name=$TF_STORAGE_ACCOUNT_NAME --account-key=$TF_STORAGE_ACCT_TOKEN
```

Create a container registry

``` bash
az acr create -n $CONTAINER_REGISTRY_NAME -g $AZURE_RESOURCE_GROUP_NAME --sku Standard --admin-enabled true

```

Get the login server

``` bash
export REGISTRY_LOGIN_SERVER=$(az acr show --name=$CONTAINER_REGISTRY_NAME --query loginServer --out tsv)
```

Get the registry credentials

``` bash
export REGISTRY_PASSWORD=$(az acr credential show --name=$CONTAINER_REGISTRY_NAME --query passwords[0].value --out tsv)
```

Choose a name for the build agent

``` bash
export BUILD_AGENT_NAME='vsts-build-agent
```

Get the name of your vsts account

``` bash
export VSTS_ACCOUNT='your-vsts-account-subdomain'
```

Create a VSTS / Azure DevOps Agent pool & name it: 

> `private-ubuntu-1804`

https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops#creating-agent-pools

Creater a Personal Access Token to be used with the agent pool:

https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops#authentication

``` bash
export VSTS_TOKEN='your_pat_secret_key_value'
```

Assign values for the linux VM

``` bash
export AGENT_ADMIN_USERNAME='some-admin-username'
export AGENT_ADMIN_PASSWORD='some-strong-password-123-!@#$%'
```

### Build the Container (if you didn't already)

`./build.sh`

### Push the Container

``` bash

./push.sh --registry=$REGISTRY_LOGIN_SERVER \
    --username=$CONTAINER_REGISTRY_NAME \
    --password=$REGISTRY_PASSWORD \
    --imageName=$BUILD_AGENT_NAME
```

### Deploy the Resources

``` bash

./deploy.sh --azureSubscriptionId=$AZURE_SUBSCRIPTION_ID \
    --azureUsername=$AZURE_USERNAME \
    --azurePassword=$AZURE_PASSWORD \
    --azureResourceGroupName=$AZURE_RESOURCE_GROUP_NAME \
    --azureArmClientId=$AZURE_ARM_CLIENT_ID \
    --azureArmClientSecret=$AZURE_ARM_CLIENT_SECRET \
    --azureArmTenantId=$AZURE_ARM_TENANT_ID \
    --azureStorageAccountName=$TF_STORAGE_ACCOUNT_NAME \
    --azureStorageAccountKey=$TF_STORAGE_ACCT_TOKEN
    --registry=$REGISTRY_LOGIN_SERVER \
    --registryUsername=$CONTAINER_REGISTRY_NAME \
    --registryPassword=$REGISTRY_PASSWORD \
    --registryImageName=$BUILD_AGENT_NAME \
    --vstsAccount=$VSTS_ACCOUNT \
    --vstsToken=$VSTS_TOKEN \
    --agentUsername=$AGENT_ADMIN_USERNAME \
    --agentPassword=$AGENT_ADMIN_PASSWORD

```

### Log into VSTS

You should now see an agent available in the `private-ubuntu-1804` agent pool

### Redeploy the agent

To redeploy the agent to the cloud, re-run `./build.sh` and push to the registry.  Then reboot the virtual machine.  The new image will automatically be pulled.

Note: it can take some time for the image to come online.
