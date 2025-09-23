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

variable "CUCUMBER_GITREPO" {
  type = string
  default = "This is defined in product tfvars"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "This is defined in product tfvars"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "This is defined in product tfvars"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "This is defined in product tfvars"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "This is defined in product tfvars"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "This is defined in product tfvars"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "This is defined in product tfvars"
}

variable "MAIL_FROM" {
  type = string
  default = "This is defined in product tfvars"
}

variable "MAIL_TO" {
  type = string
  default = "This is defined in product tfvars"
}

// sumaform specific variables
variable "SCC_USER" {
  type = string
}

variable "SCC_PASSWORD" {
  type = string
}

variable "GIT_USER" {
  type = string
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  default = null // Not needed for master, as it is public
}

variable "PROMETHEUS_PUSH_GATEWAY_URL" {
  type = string
  default = null
}