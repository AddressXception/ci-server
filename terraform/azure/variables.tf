# General Vars

variable resource_name {
    default = "vsts-agent-ubuntu-1804"
}

variable "default_resource_tags" {
  description = "The tags to associate with your network and subnets."
  type        = "map"

  default = {
    AgentPool = "private-ubuntu-18.04"
  }
}

variable "location" {
    description = "The region to deploy the resources to"
    default= "eastus"
}

# build-agent.tf Variables

variable "admin_username" {
  description = "the admin username"
}

variable "admin_password" {
  description = "the admin password"
}

variable "cloud_config_filename" {
    default = "user-data.yml.tpl"
    description = "base cloud config template"
}

variable "image_registry_server" {
    description = "The login FQDN of the image registry server"
}

variable "image_registry_username" {
    description = "the user name (or service principal id) to log into the registry"
}

variable "image_registry_password" {
    description = "the password to log into the registry"
}

variable "image_registry_image" {
    description = "the image to pull from the registry"
}

variable "resource_group_name" {
    description = "The Name of the Resource Group where Terraform will deploy"
}

variable "storage_account_name" {
    default = "vstsagentdiag"
    description = "the Name of the storage account to store logs"
}

variable "ssh_key" {
    type = "string"
    description = "The SSH public key of the machine that is allowed to configure this server.  Defaults to the deploying server.  this value must be the string key itself and not a file path"
}

# TODO: #506 - change the default SSH port
variable "ssh_port" {
    default = "22"
}

variable "standard_vm_size" {
    default = "Standard_DS1_v2"
}

variable "storage_type" {
  default = "Standard_LRS"
  description = "The type of storage for the managed os disk"
}

variable "ubuntu_image_sku" {
    default = "18.04-LTS"
    description = "The SKU of ubuntu to load"
}

variable "vnet_address_space" {
    default = "10.0.0.0/16"
}

variable "vnet_subnet_address_prefix" {
    default = "10.0.0.0/24"
}

variable "vsts_account" {
    description = "The VSTS account to log into"
}

variable "vsts_agent_name" {
    description = "The Name of the Agent"
    default = "vsts-agent-ubuntu-1804"
}

variable "vsts_agent_pool_name" {
    description = "The Name of the agent pool to associate with"
    default = "private-ubuntu-1804"
}

variable "vsts_token" { }