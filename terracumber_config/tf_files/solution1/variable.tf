// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
}

variable "CUCUMBER_GITREPO" {
  type = string
}

variable "CUCUMBER_BRANCH" {
  type = string
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

variable "HYPER" {
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
  type = list(string)
}

### Related to environment solution 1 ###

variable "mac" {
  type = map(string)
  description = "Mac to correctly update the mac address depending on environment"
}

variable "environment_number" {
  type = string
  description = "Use to set name_prefix"
}

variable "hypervisor" {
  type = string
  description = "Choose the correct hypervisor depending on environment number : 1/2 ( romulus.mgr.prv.suse.net ) 3/4 ( vulcan.mgr.prv.suse.net ) 5/6 ( hyperion.mgr.prv.suse.net ) 7/8 ( daiquiri.mgr.prv.suse.net ) 9/10 ( mojito.mgr.prv.suse.net )"
}

variable "additional_network" {
  type = string
  description = "Additional network depending on environment "
}