// Mandatory variables for terracumber
variable "CUCUMBER_COMMAND" {
  type    = string
  default = "echo EXECUTE SALT TESTS HERE"
}

variable "CUCUMBER_BRANCH" {
  type    = string
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type    = string
  default = "/root/"
}

variable "MAIL_TEMPLATE" {
  type    = string
  default = "../../mail_templates/mail-template-salt-shaker.txt"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type    = string
  default = "../../mail_templates/mail-template-salt-shaker-env-fail.txt"
}

variable "MAIL_FROM" {
  type    = string
  default = "salt-shaker@suse.de"
}

variable "MAIL_TO" {
  type    = string
  default = "salt-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type    = string
  default = null // Not needed for Salt tests
}

variable "SCC_PASSWORD" {
  type    = string
  default = null // Not needed for Salt tests
}

variable "GIT_USER" {
  type    = string
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type    = string
  default = null // Not needed for master, as it is public
}

// Environment-specific variables
variable "ENVIRONMENT" {
  type        = string
  description = "Key into ENVIRONMENT_CONFIGURATION to select the active environment (set by Jenkins)"
}

variable "ENVIRONMENT_CONFIGURATION" {
  type = map(object({
    image             = string
    mac_address       = string
    url_prefix        = string
    mail_subject      = string
    mail_subject_fail = string
    salt_obs_flavor   = string
  }))
  description = "Map of environment configurations keyed by distro name"
}
