variable "LOCATION" {
  type = string
  default = null
}

variable "KEY_FILE" {
  type = string
  default = "/home/jenkins/.ssh/testing-suma.pem"
}

// Public half of KEY_FILE, installed on the instances
variable "PUBLIC_KEY_FILE" {
  type = string
}

variable "ALLOWED_IPS" {
  type = list(string)
  default = []
}

// Prefix of the shared infrastructure (virtual network, subnets, bastion): server pipelines look it up by this prefix
variable "NAME_PREFIX" {
  type = string
  default = "mlm-bv-azure-"
}

// Existing resource group where everything is deployed: it is never created nor destroyed here
variable "RESOURCE_GROUP_NAME" {
  type = string
}

// The subscription is taken from ARM_SUBSCRIPTION_ID.
// No resource provider registration: it needs subscription-wide permissions, and Microsoft.Compute and Microsoft.Network are registered already
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

module "base" {
  source            = "./modules/base"
  // Set product_version to empty to get the public tools repositories
  product_version   = ""
  name_prefix       = var.NAME_PREFIX
  use_avahi         = false
  // Hosts are accessed with KEY_FILE only: the sumaform default ~/.ssh/id_ed25519.pub does not exist on Jenkins agents
  ssh_key_path      = null
  provider_settings = {
    location            = var.LOCATION
    resource_group_name = var.RESOURCE_GROUP_NAME
    allowed_ips         = var.ALLOWED_IPS
    key_file            = var.KEY_FILE
    public_key_location = var.PUBLIC_KEY_FILE
  }
}

output "bastion_public_name" {
  value = lookup(module.base.configuration, "bastion_host", null)
}
