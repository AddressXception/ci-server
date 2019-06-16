variable "resource_name" {
  description = "The name of the VM resource"

}

variable "vm_size" {
  description = "The SKU of the VM size"
}

variable "diag_storage_primary_blob_endpoint" {}

variable "admin_username" {
  description = "the admin username"
}

variable "admin_password" {
  description = "the admin password"
}

variable "cloud_config" {
  type = "string"
}

variable "ubuntu_image_sku" {
  description = "The SKU of ubuntu to load"
}

variable "location" {
  type = "string"
  description = "the location of the vm"
}

variable "resource_group_name" {
  type = "string"
  description = "the resource group where the VM resources will be deployed"
}

variable "subnet_id" {
  type = "string"
}

variable "storage_size_in_gb" {
  default = "128"
  description = "The size of the os storage disk"
}

variable "storage_type" {
  default = "StandardSSD_LRS"
  description = "The type of storage for the managed os disk"
}

variable "tags" {
  type = "map"
}

variable "ssh_key" {}

variable "ssh_port" {
  default = "22"
}