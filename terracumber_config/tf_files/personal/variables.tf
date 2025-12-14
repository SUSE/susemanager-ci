variable "ENVIRONMENT"{
  type = string
  description = "Personal environment"
}

variable "ENVIRONMENT_CONFIGURATION" {
  type = map
  description = "Collection of values containing: mac addresses, hypervisor and additional network"
}

variable "CUCUMBER_COMMAND" {
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
  default = "/root/spacewalk/testsuite"
}

#################################################
## Mailer configuration not use in QE pipeline ##
## Variables needed for terracumber validation ##
#################################################

variable "URL_PREFIX" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_FROM" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_TO" {
  type = string
  default = "Not Used for QE pipeline"
}

#################################################
## End mailer configuration ##
#################################################

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

variable "SCC_PTF_USER" {
  type = string
  default = null
  // Not needed for master, as PTFs are only build for SUSE Manager / MLM
}

variable "SCC_PTF_PASSWORD" {
  type = string
  default = null
  // Not needed for master, as PTFs are only build for SUSE Manager / MLM
}
