###############################################################

locals {
  availability_zones = sort(setsubtract(data.aws_availability_zones.default.names, var.excluded_availability_zones))

  environment_by_workspace = {
    production  = "production"
    development = "development"
    default     = "test"
  }
  environment = local.environment_by_workspace[terraform.workspace]

  resource_name = "${local.environment}-${var.deployment_type}"

  all_cidr_block  = "0.0.0.0/0"
  all_cidr_blocks = [local.all_cidr_block]

  tags = {
    provenance      = "terraform"
    region          = var.aws_region
    environment     = local.environment
    deployment_type = var.deployment_type
    resource_name   = local.resource_name
    Name            = local.resource_name
  }
}

###############################################################

data "aws_availability_zones" "default" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

###############################################################

resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.tags
}

###############################################################

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = local.tags
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id
  tags   = local.tags

  route {
    cidr_block = local.all_cidr_block
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "default" {

  count = var.subnet_count < length(local.availability_zones) ? var.subnet_count : length(local.availability_zones)

  subnet_id      = element(aws_subnet.default, count.index).id
  route_table_id = aws_route_table.default.id
}

###############################################################

resource "aws_subnet" "default" {

  count = var.subnet_count < length(local.availability_zones) ? var.subnet_count : length(local.availability_zones)

  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(local.availability_zones, count.index)
  tags = merge(local.tags, {
    Name = var.subnet_count > 1 ? format("${local.resource_name}-%03d", count.index + 1) : local.resource_name
  })

  timeouts {
    create = "30m"
    delete = "1m"
  }
}

###############################################################

resource "aws_route53_zone" "private" {

  count = var.private_route53_zone ? 1 : 0

  name    = var.private_route53_zone_name
  comment = "Managed by Terraform"
  tags    = local.tags

  vpc {
    vpc_id = aws_vpc.default.id
  }
}

###############################################################
