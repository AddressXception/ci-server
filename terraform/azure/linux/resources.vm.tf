# Module to set up an arbitrary VM
# based on: https://github.com/rcarmo/terraform-azure-linux-vm/blob/master/linux/main.tf

resource "azurerm_network_security_group" "inbound" {
  name                = "${var.resource_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  # Create network security rules
  # For a private agent that is unaddressable you can remove the inbound rules
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "${var.ssh_port}"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = "${var.tags}"
}

# create public ip address
# For a private agent that is unaddressable you can remove the public IP address
resource "azurerm_public_ip" "linux" {
  name                         = "${var.resource_name}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "${var.resource_group_name}-${var.resource_name}"

  tags = "${var.tags}"
}

resource "azurerm_network_interface" "nic" {
  name                      = "${var.resource_name}-nic"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${azurerm_network_security_group.inbound.id}"

  ip_configuration {
    name                          = "${var.resource_name}-config"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    # For a private agent that is unaddressable you can remove the public IP address
    public_ip_address_id          = "${azurerm_public_ip.linux.id}"
  }

  tags = "${var.tags}"
}

# create the virtual machine
resource "azurerm_virtual_machine" "linux" {
  name                  = "${var.resource_name}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  # availability sets can be created for VM's that require SLA uptime
  #availability_set_id   = "${var.availability_set_id}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "${var.vm_size}"

  # delete os and data disks when the machine is destroyed
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "${var.ubuntu_image_sku}"
    version   = "latest"
  }

  # load the vm image
  storage_os_disk {
    name              = "${var.resource_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb  = "${var.storage_size_in_gb}"
    managed_disk_type = "${var.storage_type}"
  }

  os_profile {
    computer_name  = "${var.resource_name}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"

    # pass in cloud-init to run on first run startup
    custom_data    = "${var.cloud_config}"
  }

  os_profile_linux_config {
    # Flip this bit to tue to disable logging in with a password
    disable_password_authentication = false

    # Load SSH keys. You can remove this block to disable SSH access
    ssh_keys = {
      key_data = "${var.ssh_key}"
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${var.diag_storage_primary_blob_endpoint}"
  }

  tags = "${var.tags}"
}
