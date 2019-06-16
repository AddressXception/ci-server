# Create azure resources necessary for the build-server virtual machine
# based on: https://github.com/rcarmo/terraform-azure-linux-vm

# Networking
# set up a virtual network for the machine
resource "azurerm_virtual_network" "vnet" {
  name                                = "${var.resource_name}"
  location                            = "${var.location}"
  address_space                       = ["${var.vnet_address_space}"]
  resource_group_name                 = "${var.resource_group_name}"
  tags                                = "${var.default_resource_tags}"
}

resource "azurerm_subnet" "internal" {
  name                                = "internal"
  virtual_network_name                = "${azurerm_virtual_network.vnet.name}"
  resource_group_name                 = "${var.resource_group_name}"
  address_prefix                      = "${var.vnet_subnet_address_prefix}"
}

# Generate random text for a unique storage account name
resource "random_id" "pseudo" {
  keepers = {
    resource_group                    = "${var.resource_group_name}"
    location                          = "${var.location}"
  }
  byte_length                         = 4
}

# create a storage account for VM diagnostics
resource "azurerm_storage_account" "diagnostics" {
  name                                = "${var.storage_account_name}${random_id.pseudo.hex}"
  location                            = "${var.location}"
  resource_group_name                 = "${var.resource_group_name}"
  account_replication_type            = "LRS"
  account_tier                        = "Standard"
  tags                                = "${var.default_resource_tags}"
}

# load a template cloud-init file that is run on the VM's first startup
data "template_file" "cloud_config" {
  template                            = "${file("${path.module}/../cloud-config/${var.cloud_config_filename}")}"

  vars {
    ssh_port                          = "${var.ssh_port}"
    ssh_key                           = "${var.ssh_key}"
    admin_username                    = "${var.admin_username}"
    admin_password                    = "${var.admin_password}"

    agent_name                        = "${var.vsts_agent_name}"

    # specify the env vars that will be passed to docker on startup
    docker_env_vars                   = "-e VSTS_ACCOUNT=${var.vsts_account} -e VSTS_AGENT=${var.vsts_agent_name} -e VSTS_TOKEN=${var.vsts_token} -e VSTS_POOL=${var.vsts_agent_pool_name} -e VSTS_WORK=/var/vsts -v /tmp/vsts/work/:/var/vsts"

    registry_server                   = "${var.image_registry_server}"
    registry_username                 = "${var.image_registry_username}"
    registry_password                 = "${var.image_registry_password}"
    registry_agent_image              = "${var.image_registry_image}"
  }
}

# TODO: -- enable just in time access to the vm

# initialize a linux VM resource module
module "linux" {
  source                              = "./linux"

  resource_name                       = "${var.resource_name}"
  vm_size                             = "${var.standard_vm_size}"
  location                            = "${var.location}"
  resource_group_name                 = "${var.resource_group_name}"
  ubuntu_image_sku                    = "${var.ubuntu_image_sku}"
  admin_username                      = "${var.admin_username}"
  admin_password                      = "${var.admin_password}"
  ssh_key                             = "${var.ssh_key}"
  ssh_port                            = "${var.ssh_port}"

  // pass in configuration values
  diag_storage_primary_blob_endpoint  = "${azurerm_storage_account.diagnostics.primary_blob_endpoint}"
  subnet_id                           = "${azurerm_subnet.internal.id}"
  storage_type                        = "${var.storage_type}"
  tags                                = "${var.default_resource_tags}"
  cloud_config                        = "${base64encode(data.template_file.cloud_config.rendered)}"
}
