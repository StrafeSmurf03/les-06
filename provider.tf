terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.28.0"
    }
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.3"
    }
  }
}

#Azure
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "S1204419"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "ubuntu"
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "server"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

#esxi
variable "esxi_hostname" {
  default = "192.168.1.10"
}

variable "esxi_hostport" {
  default = "22"
}

variable "esxi_hostssl" {
  default = "443"
}

variable "esxi_username" {
  default = "root"
}

variable "esxi_password" {
  default = "Welkom01!"
}

variable "ssh_username" {
    type = string
}

variable "ssh_key" {
    type = string
}

variable "ovf_file" {
  default = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
}