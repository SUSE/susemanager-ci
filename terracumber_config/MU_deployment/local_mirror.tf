// sumaform specific variables
variable "SCC_USER" {
  type = "string"
}

variable "SCC_PASSWORD" {
  type = "string"
}

variable "GIT_USER" {
  type = "string"
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = "string"
  default = null // Not needed for master, as it is public
}

provider "libvirt" {
  uri = "qemu+tcp://yuggoth.mgr.prv.suse.net/system"
}

locals {
  pool = "mnoel_disks"
}

module "base" {
  source = "./sumaform/modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "mno-"
  images = ["opensuse152o"]
  provider_settings = {
    pool = local.pool
    bridge = "br0"
    additional_network = "192.168.4.0/24"
  }
}



module "mirror" {
  source = "./sumaform/modules/mirror"

  base_configuration = module.base.configuration
  customize_minima_file = "mirror/etc/minima-customize.yaml"
  immediate_synchronization = true
  volume_provider_settings = {
    pool = local.pool
    // uncomment next line to use existing snapshot as starting point
    //    volume_snapshot_id = data.aws_ebs_snapshot.data_disk_snapshot.id
  }
}
