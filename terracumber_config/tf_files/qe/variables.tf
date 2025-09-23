variable "ENVIRONMENT"{
  type = string
  description = "Personnel environment"
}

variable "ENVIRONMENT_CONFIGURATION" {
  type = map
  description = "Collection of  value containing : mac addresses, hypervisor and additional network"
}

variable "URL_PREFIX" {
  type = string
  default = "This is defined in product tfvars"
}
