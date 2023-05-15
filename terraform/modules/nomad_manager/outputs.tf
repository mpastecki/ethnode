output "aws_instance" {
  value = {
    default = [for i in aws_instance.nomad_server : {
      id                           = i.id
      public_ip                    = i.public_ip
      private_ip                   = i.private_ip
      availability_zone            = i.availability_zone
      subnet_id                    = i.subnet_id
      primary_network_interface_id = i.primary_network_interface_id
      tags                         = i.tags
    }]
  }
}

output "ssh_private_key" {
  value = tls_private_key.default_key.id
}
