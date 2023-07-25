// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "Define in product tfvars"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "Define in product tfvars"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "Define in product tfvars"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
}

variable "MAIL_TEMPLATE" {
  type = string
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Failed acceptance tests on Pull Request: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
}

variable "ENVIRONMENT" {
  type = string
}

variable "MAIL_FROM" {
  type = string
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-ci@suse.de"
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

// Repository containing the build for the tested Uyuni Pull Request
variable "PULL_REQUEST_REPO" {
  type = string
}

variable "MASTER_REPO" {
  type = string
}

variable "MASTER_OTHER_REPO" {
  type = string
}

variable "MASTER_SUMAFORM_TOOLS_REPO" {
  type = string
}

variable "UPDATE_REPO" {
  type = string
}

variable "ADDITIONAL_REPO_URL" {
  type = string
}

variable "TEST_PACKAGES_REPO" {
  type = string
}

// Repositories containing the client tools RPMs
variable "SLE_CLIENT_REPO" {
  type = string
}

variable "RHLIKE_CLIENT_REPO" {
  type = string
}

variable "DEBLIKE_CLIENT_REPO" {
  type = string
}

variable "OPENSUSE_CLIENT_REPO" {
  type = string
}

variable "IMAGE" {
  type = string
}

variable "GIT_PROFILES_REPO" {
  type = string
}

variable "IMAGES" {
  type = list(string)
}

variable "PRODUCT_VERSION" {
  type = string
}

variable "MIRROR" {
  type = string
}

variable "USE_MIRROR" {
  type = bool
}

variable "DOMAIN" {
  type = string
}

variable "BRIDGE" {
  type = string
}

variable "ENVIRONMENT_CONFIGURATION" {
  type = map
  description = "Collection of  value containing : mac addresses, hypervisor and additional network"
}
