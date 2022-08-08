provider "aviatrix" {
  controller_ip           = var.aviatrix_controller_ip
  username                = var.aviatrix_username
  password                = var.aviatrix_password
  skip_version_validation = "true" # Only needed if running Aviatrix Controller version 6.5
}

provider "aws" {
  region = "us-west-2"
}

provider "google" {
  credentials = var.gcloud_project_credentials_filepath
}

resource "aviatrix_account" "aws_ma" {
  account_name       = var.aws_account_name_ma
  cloud_type         = 1
  aws_account_number = var.aws_account_id_ma
  aws_iam            = true
}

resource "aviatrix_account" "gcp" {
  account_name                        = var.gcp_account_name
  cloud_type                          = 4
  gcloud_project_id                   = var.gcloud_project_id
  gcloud_project_credentials_filepath = var.gcloud_project_credentials_filepath
}

resource "aws_s3_bucket" "backups_s3" {
  bucket_prefix = "aviatrix-backups"
  force_destroy = true
  tags = {
    Name = "aviatrix-backups"
  }
}

resource "aws_s3_bucket_public_access_block" "backups_block" {
  bucket                  = aws_s3_bucket.backups_s3.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aviatrix_controller_config" "backup_config" {
  backup_configuration = true
  backup_cloud_type    = 1
  backup_account_name  = var.aws_account_name
  backup_bucket_name   = aws_s3_bucket.backups_s3.id
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["sharedsvcsdr12"]
  }
}

data "aws_subnet" "subnet" {
  filter {
    name   = "tag:Name"
    values = ["sharedsvcsdr12-subnet"]
  }
}

data "aws_subnet" "subnet-ha" {
  filter {
    name   = "tag:Name"
    values = ["sharedsvcsdr12-subnet-ha"]
  }
}

resource "aws_cloudformation_stack" "controller_ha" {
  name         = "AviatrixControllerHA"
  capabilities = ["CAPABILITY_NAMED_IAM"]
  template_url = "https://s3-us-west-2.amazonaws.com/aviatrix-cloudformation-templates/aviatrix-aws-existing-controller-ha.json"
  parameters = {
    VPCParam                  = data.aws_vpc.vpc.id
    SubnetParam               = join(",", [data.aws_subnet.subnet.id, data.aws_subnet.subnet-ha.id])
    AviatrixTagParam          = var.controller_name
    S3BucketBackupParam       = aws_s3_bucket.backups_s3.id
    NotifEmailParam           = var.admin_email
    PrivateAccess             = "False"
    CustomAviatrixAppRoleName = var.app_role_name
    CustomAviatrixEC2RoleName = var.ec2_role_name
  }
  depends_on = [
    aviatrix_controller_config.backup_config
  ]
}

resource "aviatrix_copilot_association" "copilot_association" {
  copilot_address = var.aviatrix_copilot_ip
}

module "transit-peering" {
  source  = "terraform-aviatrix-modules/mc-transit-peering/aviatrix"
  version = "1.0.5"
  transit_gateways = [
    module.awstgw13.transit_gateway.gw_name,
    module.awstgw14.transit_gateway.gw_name,
    module.gcptgw16.transit_gateway.gw_name,
    module.gcptgw17.transit_gateway.gw_name
  ]
}

resource "aviatrix_segmentation_security_domain" "prod" {
  domain_name = "Prod"
  depends_on = [
    module.awstgw13.transit_gateway,
    module.awstgw14.transit_gateway,
    module.gcptgw16.transit_gateway,
    module.gcptgw17.transit_gateway
  ]
}

resource "aviatrix_segmentation_security_domain" "dev" {
  domain_name = "Dev"
  depends_on = [
    module.awstgw13.transit_gateway,
    module.awstgw14.transit_gateway,
    module.gcptgw16.transit_gateway,
    module.gcptgw17.transit_gateway
  ]
}

resource "aviatrix_segmentation_security_domain" "tableau" {
  domain_name = "Tableau"
  depends_on = [
    module.awstgw13.transit_gateway,
    module.awstgw14.transit_gateway,
    module.gcptgw16.transit_gateway,
    module.gcptgw17.transit_gateway
  ]
}

resource "aviatrix_segmentation_security_domain" "onprem" {
  domain_name = "Onprem"
  depends_on = [
    module.awstgw13.transit_gateway,
    module.awstgw14.transit_gateway,
    module.gcptgw16.transit_gateway,
    module.gcptgw17.transit_gateway
  ]
}

resource "aviatrix_segmentation_security_domain" "sharedservices" {
  domain_name = "SharedServices"
  depends_on = [
    module.awstgw13.transit_gateway,
    module.awstgw14.transit_gateway,
    module.gcptgw16.transit_gateway,
    module.gcptgw17.transit_gateway
  ]
}

resource "aviatrix_segmentation_security_domain" "nat_spoke" {
  domain_name = "NAT-Spoke"
  depends_on = [
    module.awstgw13.transit_gateway,
    module.awstgw14.transit_gateway,
    module.gcptgw16.transit_gateway,
    module.gcptgw17.transit_gateway
  ]
}