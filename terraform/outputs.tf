output "instances" {
  value = {
    default = [for i in module.ethnode.aws_instance.default : {
      id                = i.id
      public_ip         = i.public_ip
      private_ip        = i.private_ip
      availability_zone = i.availability_zone
      subnet_id         = i.subnet_id
      tags              = i.tags
    }]
  }
}

output "ssh_private_key" {
  value = "${module.ethnode.ssh_private_key}-eth-node-ssh-key.pem"
}

output "first_instance_public_ip" {
  value = module.ethnode.aws_instance.default[0].public_ip
}
