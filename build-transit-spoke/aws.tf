# us-west-2

data "aws_internet_gateway" "igw" {
  filter {
    name   = "tag:Name"
    values = ["sharedsvcsdr12-igw"]
  }
}

resource "aws_subnet" "psf_subnet" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block = "10.12.2.0/24"
  tags = {
    Name = "psf-subnet"
  }
}

resource "aws_route_table" "psf_rtb" {
  vpc_id = data.aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw.internet_gateway_id
  }
  tags = {
    Name = "psf-rtb"
  }
  lifecycle {
    ignore_changes = [
      route
    ]
  }
}

resource "aws_route_table_association" "psf_rtb_association" {
  subnet_id      = aws_subnet.psf_subnet.id
  route_table_id = aws_route_table.psf_rtb.id
}

resource "aws_subnet" "psf_subnet_ha" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block = "10.12.3.0/24"
  tags = {
    Name = "psf-subnet-ha"
  }
}

resource "aws_route_table" "psf_rtb_ha" {
  vpc_id = data.aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw.internet_gateway_id
  }
  tags = {
    Name = "psf-rtb-ha"
  }
  lifecycle {
    ignore_changes = [
      route
    ]
  }
}

resource "aws_route_table_association" "psf_rtb_association_ha" {
  subnet_id      = aws_subnet.psf_subnet_ha.id
  route_table_id = aws_route_table.psf_rtb_ha.id
}

resource "aviatrix_gateway" "psf" {
  gw_name                                     = "psf-gateway"
  vpc_id                                      = data.aws_vpc.vpc.id
  cloud_type                                  = 1
  vpc_reg                                     = "us-west-2"
  account_name                                = var.aws_account_name
  gw_size                                     = "t3.small"
  subnet                                      = "10.12.4.0/26"
  zone                                        = "us-west-2a"
  peering_ha_gw_size                          = "t3.small"
  peering_ha_subnet                           = "10.12.4.64/26"
  peering_ha_zone                             = "us-west-2b"
  enable_encrypt_volume                       = true
  enable_public_subnet_filtering              = true
  public_subnet_filtering_route_tables        = [aws_route_table.psf_rtb.id]
  public_subnet_filtering_ha_route_tables     = [aws_route_table.psf_rtb_ha.id]
  public_subnet_filtering_guard_duty_enforced = false
}

resource "aws_subnet" "spoke_subnet" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block = "10.12.5.0/24"
  tags = {
    Name = "spoke-subnet"
  }
}

resource "aws_route_table" "spoke_rtb" {
  vpc_id = data.aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw.internet_gateway_id
  }
  tags = {
    Name = "spoke-rtb"
  }
  lifecycle {
    ignore_changes = [
      route
    ]
  }
}

resource "aws_route_table_association" "spoke_rtb_association" {
  subnet_id      = aws_subnet.spoke_subnet.id
  route_table_id = aws_route_table.spoke_rtb.id
}

module "sharedservices_spoke" {
  source           = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version          = "1.1.0"
  cloud            = "AWS"
  name             = "sharedservices-spoke"
  region           = "us-west-2"
  cidr             = "10.12.0.0/16"
  account          = var.aws_account_name
  transit_gw       = module.awstgw13.transit_gateway.gw_name
  security_domain  = aviatrix_segmentation_security_domain.sharedservices.domain_name
  ha_gw            = false
  use_existing_vpc = true
  vpc_id           = data.aws_vpc.vpc.id
  gw_subnet        = aws_subnet.spoke_subnet.cidr_block
}

module "awstgw13" {
  source              = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version             = "1.1.2"
  cloud               = "AWS"
  name                = "awstgw13"
  region              = "us-west-2"
  cidr                = "10.13.0.0/16"
  account             = var.aws_account_name
  enable_segmentation = true
  insane_mode         = true
}

module "prod1" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "prod1"
  region          = "us-west-2"
  cidr            = "10.1.0.0/16"
  account         = var.aws_account_name
  transit_gw      = module.awstgw13.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.prod.domain_name
  ha_gw           = false
}

resource "aviatrix_gateway" "egress" {
  cloud_type     = 1
  account_name   = var.aws_account_name
  gw_name        = "egress"
  vpc_id         = module.prod1.vpc.vpc_id
  vpc_reg        = "us-west-2"
  gw_size        = "t2.micro"
  subnet         = module.prod1.vpc.public_subnets[0].cidr
  single_ip_snat = true
}

resource "aviatrix_fqdn" "egress_fqdn" {
  fqdn_tag            = "Egress Traffic"
  fqdn_enabled        = true
  fqdn_mode           = "white"
  manage_domain_names = false
  gw_filter_tag_list {
    gw_name = aviatrix_gateway.egress.gw_name
  }
}

resource "aviatrix_fqdn_tag_rule" "tag_rule" {
  fqdn_tag_name = aviatrix_fqdn.egress_fqdn.fqdn_tag
  fqdn          = "salesforce.com"
  protocol      = "tcp"
  port          = "443"
  action        = "Allow"
}

module "dev2" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "dev2"
  region          = "us-west-2"
  cidr            = "10.2.0.0/16"
  account         = var.aws_account_name
  transit_gw      = module.awstgw13.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.dev.domain_name
  ha_gw           = false
}

# us-east-1

module "awstgw14" {
  source                  = "terraform-aviatrix-modules/aws-transit-firenet/aviatrix"
  version                 = "5.0.0"
  name                    = "awstgw14"
  region                  = "us-east-1"
  account                 = var.aws_account_name
  cidr                    = "10.14.0.0/16"
  firewall_image          = "Palo Alto Networks VM-Series Next-Generation Firewall (BYOL)"
  prefix                  = false
  suffix                  = false
  bootstrap_bucket_name_1 = aws_s3_bucket.pan_bootstrap_s3.bucket
  iam_role_1              = var.ec2_role_name
  enable_segmentation     = true
  insane_mode             = true
  firewall_image_version  = "10.1.4"
  egress_enabled          = true
  local_as_number         = "64774"
}

module "nat_spoke" {
  source                   = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                  = "1.1.0"
  cloud                    = "AWS"
  name                     = "nat-spoke"
  region                   = "us-east-1"
  cidr                     = "172.28.1.0/24"
  account                  = var.aws_account_name
  transit_gw               = module.awstgw14.transit_gateway.gw_name
  security_domain          = aviatrix_segmentation_security_domain.nat_spoke.domain_name
  auto_advertise_s2c_cidrs = true
}

resource "aviatrix_site2cloud" "nat_spoke" {
  vpc_id                     = module.nat_spoke.vpc.vpc_id
  connection_name            = "mna19_tgw"
  connection_type            = "mapped"
  remote_gateway_type        = "generic"
  tunnel_type                = "route"
  remote_gateway_ip          = var.mna19_tgw_ip1
  primary_cloud_gateway_name = module.nat_spoke.spoke_gateway.gw_name
  pre_shared_key             = var.mna19_tgw_psk1
  ha_enabled                 = true
  backup_remote_gateway_ip   = var.mna19_tgw_ip2
  backup_gateway_name        = module.nat_spoke.spoke_gateway.ha_gw_name
  backup_pre_shared_key      = var.mna19_tgw_psk2
  remote_subnet_cidr         = var.mna19_tgw_nat["remote_subnet_cidr"]
  remote_subnet_virtual      = var.mna19_tgw_nat["remote_subnet_virtual"]
  local_subnet_cidr          = var.mna19_tgw_nat["local_subnet_cidr"]
  local_subnet_virtual       = var.mna19_tgw_nat["local_subnet_virtual"]
  forward_traffic_to_transit = true
  depends_on = [
    module.nat_spoke
  ]
}

resource "aviatrix_segmentation_security_domain_connection_policy" "nat_spoke_to_prod3" {
  domain_name_1 = aviatrix_segmentation_security_domain.nat_spoke.domain_name
  domain_name_2 = aviatrix_segmentation_security_domain.prod.domain_name
}

module "prod3" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "prod3"
  region          = "us-east-1"
  cidr            = "10.3.0.0/16"
  account         = var.aws_account_name
  transit_gw      = module.awstgw14.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.prod.domain_name
  enable_bgp      = true
  local_as_number = "64719"
}

module "dev4" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "AWS"
  name            = "dev4"
  region          = "us-east-1"
  cidr            = "10.4.0.0/16"
  account         = var.aws_account_name
  transit_gw      = module.awstgw14.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.dev.domain_name
  ha_gw           = false
}

module "tableau5" {
  source                           = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                          = "1.1.0"
  cloud                            = "AWS"
  name                             = "tableau5"
  region                           = "us-east-1"
  account                          = var.aws_account_name
  transit_gw                       = module.awstgw14.transit_gateway.gw_name
  security_domain                  = aviatrix_segmentation_security_domain.tableau.domain_name
  ha_gw                            = false
  included_advertised_spoke_routes = "10.33.1.1/32,10.33.1.2/32"
  use_existing_vpc                 = true
  vpc_id                           = var.tableau5_vpc_id
  gw_subnet                        = var.tableau5_gw_subnet
}

module "tableau5_nat" {
  source          = "./modules/mc-overlap-nat-spoke"
  spoke_gw_object = module.tableau5.spoke_gateway
  spoke_cidrs     = ["10.3.0.0/16"]
  transit_gw_name = module.awstgw14.transit_gateway.gw_name
  gw1_snat_addr   = "10.33.1.1"
  gw2_snat_addr   = "10.33.1.2"
  depends_on = [
    module.tableau5,
    module.awstgw14
  ]
}