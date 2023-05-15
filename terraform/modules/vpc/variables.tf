###############################################################

variable "subnet_count" {
  type        = number
  description = "The number of subnets to deploy."
}

variable "private_route53_zone" {
  type        = bool
  description = "Whether to provision a private route53 zone for the VPC."
  default     = false
}

variable "private_route53_zone_name" {
  type        = string
  description = "The private route53 zone name."
  default     = "marcin.internal"
}

variable "excluded_availability_zones" {
  type    = list(string)
  default = []
}

variable "aws_region" {
  type        = string
  description = ""
  default     = "ca-central-1"
}

variable "deployment_type" {
  type        = string
  description = "The purpose of the deployment - used when labelling resources, etc."
}

###############################################################
