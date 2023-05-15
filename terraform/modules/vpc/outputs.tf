###############################################################

output "aws_vpc" {
  value = {
    default = {
      id         = aws_vpc.default.id
      cidr_block = aws_vpc.default.cidr_block
    }
  }
}

output "aws_subnet" {
  value = {
    default = [for s in aws_subnet.default : {
      id                = s.id
      cidr_block        = s.cidr_block
      availability_zone = s.availability_zone
    }]
  }
}

output "aws_route53_zone" {
  value = {
    private = [for z in aws_route53_zone.private : {
      id   = z.id
      name = z.name
    }]
  }
}

###############################################################
