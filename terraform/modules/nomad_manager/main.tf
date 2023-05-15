// EC2 instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

// Key pair
resource "tls_private_key" "default_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "default_key_pair" {
  key_name   = "${var.resource_name}-ssh-key"
  public_key = tls_private_key.default_key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.default_key.private_key_openssh}' > ./${tls_private_key.default_key.id}-${var.resource_name}-ssh-key.pem; chmod 400 ./${tls_private_key.default_key.id}-${var.resource_name}-ssh-key.pem"
  }

  tags = var.tags
}

// Nomad Managers
resource "aws_instance" "nomad_server" {

  for_each = {
    for index, instance in var.instances_setup :
    instance.name => instance
  }

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = each.value.instance_type
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.default.name
  disable_api_termination     = var.prevent_destroy
  subnet_id                   = element(var.vpc_subnets_ids, each.value.subnet_index)
  key_name                    = aws_key_pair.default_key_pair.key_name

  root_block_device {
    volume_size           = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
    delete_on_termination = true

    encrypted = true

    tags = merge(var.tags, {
      Name = "${var.resource_name}-${each.value.name}"
    })
  }

  user_data = templatefile("${path.module}/scripts/user_data.sh", {})

  tags = merge(var.tags, {
    Name                   = "${var.resource_name}-${each.value.name}",
    ebs_volume_device_name = var.ebs_volume_device_name
  })

  timeouts {
    create = "10m"
    update = "10m"
    delete = "20m"
  }

  lifecycle {
    ignore_changes = [
      ami,
      volume_tags,
      key_name,
      user_data,
      user_data_replace_on_change,
      ebs_block_device,
    ]
  }

  depends_on = [
    aws_iam_instance_profile.default,
  ]
}

// nomad_server_sg
resource "aws_network_interface_sg_attachment" "nomad_server_sg_attachment_nomad_server_sg" {
  for_each = aws_instance.nomad_server

  security_group_id    = aws_security_group.nomad_server.id
  network_interface_id = each.value.primary_network_interface_id
}

// EBS Volumes

resource "aws_ebs_volume" "nomad_manager_ebs" {

  for_each = {
    for index, instance in var.instances_setup :
    instance.name => instance
  }

  availability_zone = element(var.vpc_subnets_zones, each.value.subnet_index)
  size              = each.value.ebs_volume_size
  type              = each.value.ebs_volume_type

  encrypted = true

  tags = merge(var.tags, {
    Name = "${var.resource_name}-${each.value.name}"
  })
}

resource "aws_volume_attachment" "ebs_att" {
  for_each = aws_ebs_volume.nomad_manager_ebs

  device_name = var.ebs_volume_device_name
  volume_id   = each.value.id
  instance_id = aws_instance.nomad_server[each.key].id
}

resource "aws_security_group" "nomad_server" {
  name        = "${var.resource_name}-nomad-server"
  description = "Allow Nomad server traffic"
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name          = "${var.resource_name}-nomad-server"
    resource_name = "${var.resource_name}-nomad-server"
  })

  # SSH from subnets
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(var.vpc_subnets_cidrs, var.ssh_cidr_blocks)
  }

  # nomad (server): https, hvn subnet added for the nomad secrets backend
  ingress {
    description = ""
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = var.vpc_subnets_cidrs
  }
  egress {
    description = ""
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = var.vpc_subnets_cidrs
  }

  # nomad (server): rpc
  ingress {
    description = ""
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = var.vpc_subnets_cidrs
  }
  egress {
    description = ""
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = var.vpc_subnets_cidrs
  }

  ingress {
    description = "Nomad serf WAN"
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = var.vpc_subnets_cidrs
  }

  ingress {
    description = "Nomad serf WAN"
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = var.vpc_subnets_cidrs
  }

  egress {
    description = "Nomad serf WAN"
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = var.vpc_subnets_cidrs
  }

  egress {
    description = "Nomad serf WAN"
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = var.vpc_subnets_cidrs
  }

  lifecycle {
    create_before_destroy = true
  }
}

// IAM Role and EC2 Profile

data "aws_iam_policy_document" "default" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nomad_managers" {
  name                  = "${var.resource_name}-nomad-managers"
  assume_role_policy    = data.aws_iam_policy_document.default.json
  force_detach_policies = true
  tags = merge(var.tags, {
    Name          = "aws-iam-role-nomad-managers"
    resource_name = "${var.resource_name}-aws-iam-role-nomad-managers"
  })
}

resource "aws_iam_instance_profile" "default" {
  name = "${var.resource_name}-nomad-managers"
  role = aws_iam_role.nomad_managers.name
}
