variable "resource_name" {
  type    = string
  default = "eth-node"
}

variable "tags" {
  type = map(string)
  default = {
    provenance = "terraform"
  }
}

variable "instances_setup" {
  type = list(object({
    name             = string
    subnet_index     = number
    instance_type    = string
    root_volume_size = number
    root_volume_type = string
    ebs_volume_size  = number
    ebs_volume_type  = string
  }))
  default = [
    {
      name             = "nomad-manager-001",
      subnet_index     = 0,
      instance_type    = "t3.medium",
      root_volume_size = 20,
      root_volume_type = "gp3",
      ebs_volume_size  = "100",
      ebs_volume_type  = "gp3"
    }

  ]
}

variable "prevent_destroy" {
  type    = bool
  default = true

}

variable "vpc_subnets_ids" {
  type = list(string)
}

variable "vpc_subnets_zones" {
  type = list(string)
}

variable "vpc_subnets_cidrs" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "ebs_volume_device_name" {
  type    = string
  default = "/dev/sdh"
}

variable "ssh_cidr_blocks" {
  type    = list(string)
  default = []
}
