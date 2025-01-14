locals {
  ipv4_vpc_cidr_block = "10.0.0.0/16"
  ipv4_default_route  = "0.0.0.0/0"
}

resource "aws_vpc" "FCC_VPC" {
  cidr_block           = local.ipv4_vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "FCC_VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.FCC_VPC.id

  tags = {
    Name = "FCC IGW"
  }

  depends_on = [aws_vpc.FCC_VPC]
}

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.FCC_VPC.default_route_table_id
  route {
    cidr_block = local.ipv4_default_route
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_subnet" "FCC_Subnet" {
  for_each = {
    Public-2A = {
      vpc_id            = aws_vpc.FCC_VPC.id
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-west-2a"
    }
    Public-2B = {
      vpc_id            = aws_vpc.FCC_VPC.id
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-west-2b"
    }
    Private-2A = {
      vpc_id            = aws_vpc.FCC_VPC.id
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-west-2a"
    }
    Private-2B = {
      vpc_id            = aws_vpc.FCC_VPC.id
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-west-2b"
    }
  }
  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}

resource "aws_security_group" "FCC_SGs" {

  for_each = {
    public-web = {
      name        = "Public-Web"
      description = "Publicly accessible sg"
    }
    private = {
      name        = "Private"
      description = "Private network sg"
    }
  }

  vpc_id      = aws_vpc.FCC_VPC.id
  name        = each.value.name
  description = each.value.description

  tags = {
    "created-through" = "FCC"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  for_each = {
    allow_local_echo_public = {
      security_group_id = aws_security_group.FCC_SGs["public-web"].id
      description       = "Allow local echo"
      ip_protocol       = "icmp"
      to_port           = -1
      from_port         = 8
      cidr_ipv4         = local.ipv4_vpc_cidr_block
    }
    allow_incoming_http_public = {
      security_group_id = aws_security_group.FCC_SGs["public-web"].id
      description       = "Allow port 80 incoming for public connections"
      ip_protocol       = "tcp"
      to_port           = 80
      from_port         = 80
      cidr_ipv4         = local.ipv4_default_route
    }
    allow_local_echo_private = {
      security_group_id = aws_security_group.FCC_SGs["private"].id
      description       = "Allow local echo"
      ip_protocol       = "icmp"
      to_port           = -1
      from_port         = 8
      cidr_ipv4         = local.ipv4_vpc_cidr_block
    }
    allow_http_private = {
      security_group_id            = aws_security_group.FCC_SGs["private"].id
      description                  = "Allow HTTP from public sg"
      ip_protocol                  = "tcp"
      to_port                      = 80
      from_port                    = 80
      referenced_security_group_id = aws_security_group.FCC_SGs["public-web"].id
    }
    allow_ssh_public = {
      security_group_id = aws_security_group.FCC_SGs["public-web"].id
      description       = "Allow ssh"
      ip_protocol       = "tcp"
      to_port           = 22
      from_port         = 22
      cidr_ipv4         = local.ipv4_default_route
    }
  }

  security_group_id            = each.value.security_group_id
  description                  = each.value.description
  ip_protocol                  = each.value.ip_protocol
  to_port                      = each.value.to_port != null ? each.value.to_port : null
  from_port                    = each.value.from_port != null ? each.value.from_port : null
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_egress_rule" "egress_rules" {
  for_each = {
    allow_egress_public = {
      security_group_id = aws_security_group.FCC_SGs["public-web"].id
      description       = "Allow all egress."
      ip_protocol       = "all"
      cidr_ipv4         = local.ipv4_default_route
    }
    private = {
      security_group_id = aws_security_group.FCC_SGs["private"].id
      description       = "Allow all egress."
      ip_protocol       = "all"
      cidr_ipv4         = local.ipv4_default_route
    }
  }
  security_group_id = each.value.security_group_id
  description       = each.value.description
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
}


# Uncomment below if you want to use the nat-gateway. Elastic IPs do cost money, be aware of this. An hour of usage is about $0.09 per hour as of the time this was published.


# resource "aws_nat_gateway" "nat_gw" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.FCC_Subnet["Public-2A"].id
#   depends_on    = [aws_subnet.FCC_Subnet, aws_internet_gateway.igw]
# }

# resource "aws_eip" "nat_eip" {
#   domain = "vpc"
# }

# resource "aws_route_table" "route_tables" {
#   for_each = {
#     Private-RT = {
#       routes = [
#         {
#           cidr_block     = local.ipv4_default_route
#           nat_gateway_id = aws_nat_gateway.nat_gw.id
#         }
#       ]
#     }
#   }
#   vpc_id = aws_vpc.FCC_VPC.id

#   tags = {
#     Name = each.key
#   }
# }

# resource "aws_route_table_association" "route_associations" {
#   for_each = {
#     Private-2A = {
#       subnet_id      = aws_subnet.FCC_Subnet["Private-2A"].id
#       route_table_id = aws_route_table.route_tables["Private-RT"].id
#     }
#     Private-2B = {
#       subnet_id      = aws_subnet.FCC_Subnet["Private-2B"].id
#       route_table_id = aws_route_table.route_tables["Private-RT"].id
#     }
#   }


#   subnet_id      = each.value.subnet_id
#   route_table_id = each.value.route_table_id
#   depends_on     = [aws_subnet.FCC_Subnet]
# }
