# Get my public IP to open SSH communication
data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

module "vpc" {

  source = "./modules/vpc"

  subnet_count         = 3
  deployment_type      = "ethnode"
  aws_region           = "us-east-1"
  private_route53_zone = true
  excluded_availability_zones = [
    "us-east-1c",
    "us-east-1e",
    "us-east-1f",
  ]
}

module "ethnode" {

  source = "./modules/nomad_manager"

  resource_name = "eth-node"

  instances_setup = [{
    name             = "eth-node-001",
    subnet_index     = 0,
    instance_type    = "t3.medium",
    root_volume_size = 20,
    root_volume_type = "gp3",
    ebs_volume_size  = 100,
    ebs_volume_type  = "gp3"
  }]

  vpc_id            = module.vpc.aws_vpc.default.id
  vpc_subnets_ids   = module.vpc.aws_subnet.default.*.id
  vpc_subnets_zones = module.vpc.aws_subnet.default.*.availability_zone
  vpc_subnets_cidrs = module.vpc.aws_subnet.default.*.cidr_block
  ssh_cidr_blocks   = ["${chomp(data.http.my_public_ip.body)}/32"]

  tags = {
    provenance      = "terraform"
    region          = "us-east-1"
    environment     = "development"
    tf_workspace    = terraform.workspace
    deployment_type = "ethnode"
    resource_name   = "development-ethnode"
    Name            = "development-ethnode"
  }
}

resource "aws_security_group" "eth_node" {
  name        = "ethereum-node"
  description = "Allow P2P Discovery"
  vpc_id      = module.vpc.aws_vpc.default.id
  tags = {
    Name = "security-group-ethereum-node"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "p2p_discovery_tcp" {
  type              = "ingress"
  from_port         = 30303
  to_port           = 30303
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eth_node.id
}

resource "aws_security_group_rule" "p2p_discovery_udp" {
  type              = "ingress"
  from_port         = 30303
  to_port           = 30303
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eth_node.id
}

resource "aws_network_interface_sg_attachment" "ethnode_sg_attachment_eth_node_sg" {
  for_each = toset(module.ethnode.aws_instance.default.*.primary_network_interface_id)

  security_group_id    = aws_security_group.eth_node.id
  network_interface_id = each.value
}
