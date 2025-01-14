data "aws_ami" "free-linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami]
  }
  owners = ["amazon"]
}
locals {
  key_pair_name = "ec2"
}

resource "aws_key_pair" "ssh_Key" {
  key_name   = local.key_pair_name
  public_key = file(var.public_key)
}

resource "aws_instance" "FCC_Instances" {
  for_each = {
    PUBLIC_2A = {
      ami               = data.aws_ami.free-linux.id
      instance_type     = var.instance_type
      public_ip_address = true
      security_group_id = [aws_security_group.FCC_SGs["public-web"].id]
      subnet_id         = aws_subnet.FCC_Subnet["Public-2A"].id
      key_name          = local.key_pair_name
    }
    PUBLIC_2B = {
      ami               = data.aws_ami.free-linux.id
      instance_type     = var.instance_type
      public_ip_address = true
      security_group_id = [aws_security_group.FCC_SGs["public-web"].id]
      subnet_id         = aws_subnet.FCC_Subnet["Public-2B"].id
      key_name          = local.key_pair_name
    }
  }

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  associate_public_ip_address = each.value.public_ip_address
  vpc_security_group_ids      = each.value.security_group_id
  subnet_id                   = each.value.subnet_id
  key_name                    = try(each.value.key_name, null)
  user_data                   = file(var.shell_command)

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = each.key
  }
}
