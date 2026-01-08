variable "ENVIRONMENT_CONFIGURATION" {
  type = any
  description = "Collection of values containing: mac addresses, hypervisor and additional network"
}

variable "PLATFORM_LOCATION_CONFIGURATION" {
  type = any
  description = "Collection of values containing location specific information"
}

variable LOCATION {
  type = string
  description = "Platform location"
}

variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  description = "Testsuite git repository"
  default = "https://github.com/uyuni-project/uyuni.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  description = "Testsuite git branch"
  default = "master"
}

variable "GIT_USER" {
  type = string
  description = "Git user to access git repository"
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  description = "Git user password to access git repository"
  default = null // Not needed for master, as it is public
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}
variable "URL_PREFIX" {
  type = string
  default = "Not Used for QE pipeline"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Set in TFVARS"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Set in TFVARS"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "galaxy-noise@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-noise@suse.de"
}

#################################################
## End mailer configuration ##
#################################################

// sumaform specific variables
variable "SCC_USER" {
  type = string
  description = "SCC user used as product organization"
}

variable "SCC_PASSWORD" {
  type = string
  description = "SCC password used as product organization"
}

variable "SCC_PTF_USER" {
  type = string
  description = "SCC user used for PTF Feature testing, only available for 5.1"
  default = null
}

variable "SCC_PTF_PASSWORD" {
  type = string
  description = "SCC user used for PTF Feature testing, only available for 5.1"
  default = null
}

variable "SERVER_CONTAINER_REPOSITORY" {
  type = string
  description = "Server container registry path"
  default = ""
}

variable "PROXY_CONTAINER_REPOSITORY" {
  type = string
  description = "Proxy container registry path, not needed for 4.3"
  default = ""
}

variable "SERVER_CONTAINER_IMAGE" {
  type = string
  description = "Server container image, not needed for 4.3"
  default = ""
}

variable "ZVM_ADMIN_TOKEN" {
  type = string
  description = "Admin token for Feilong provider"
}

variable "BASE_OS" {
  type        = string
  description = "Optional override for the server base OS image"
  default     = null
}

variable "PRODUCT_VERSION" {
  type        = string
  default       = null
}

variable "BASE_CONFIGURATIONS" {
  type        = map
  description = "Describe the base configuration (default core for NUE and all bases for SLC1)"
}
