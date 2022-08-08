resource "aws_ebs_volume" "copilot_vol1" {
  availability_zone = module.copilot_build_aws.availability_zone
  size              = 8
  tags = {
    Name = "Aviatrix CoPilot Volume 1"
  }
}

module "copilot_build_aws" {
  source               = "./modules/copilot_build_aws"
  copilot_name         = var.copilot_name
  use_existing_keypair = true
  keypair              = var.keypair
  use_existing_vpc     = true
  vpc_id               = aws_vpc.vpc.id
  subnet_id            = aws_subnet.subnet.id

  allowed_cidrs = {
    "tcp_cidrs" = {
      protocol = "tcp"
      port     = "443"
      cidrs    = ["0.0.0.0/0"]
    }
    "udp_cidrs_1" = {
      protocol = "udp"
      port     = "5000"
      cidrs    = ["0.0.0.0/0"]
    }
    "udp_cidrs_2" = {
      protocol = "udp"
      port     = "31283"
      cidrs    = ["0.0.0.0/0"]
    }
  }

  additional_volumes = {
    "one" = {
      device_name = "/dev/sdf"
      volume_id   = aws_ebs_volume.copilot_vol1.id
    }
  }
  depends_on = [
    aws_key_pair.keypair
  ]
}