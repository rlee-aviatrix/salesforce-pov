# us-west1 

module "gcptgw16" {
  source                = "./modules/gcp-transit-firenet"
  name                  = "gcptgw16"
  account               = aviatrix_account.gcp.account_name
  gcloud_project_id     = var.gcloud_project_id
  transit_cidr          = "10.16.0.0/16"
  firewall_cidr         = "10.200.0.0/18"
  region                = "us-west1"
  firewall_image        = "Palo Alto Networks VM-Series Next-Generation Firewall BYOL~9.1.3"
  bootstrap_bucket_name = module.gcp_pan_bootstrap_storage.name
  enable_segmentation   = true
  hpe                   = true
  instance_size         = "n1-highcpu-4"
  egress_enabled        = true
}

module "prod7" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "GCP"
  name            = "prod7"
  region          = "us-west1"
  cidr            = "10.7.0.0/16"
  account         = aviatrix_account.gcp.account_name
  transit_gw      = module.gcptgw16.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.prod.domain_name
}

module "dev6" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "GCP"
  name            = "dev6"
  region          = "us-west1"
  cidr            = "10.6.0.0/16"
  account         = aviatrix_account.gcp.account_name
  transit_gw      = module.gcptgw16.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.dev.domain_name
  ha_gw           = false
}

# us-east1

module "gcptgw17" {
  source              = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version             = "1.1.2"
  cloud               = "GCP"
  name                = "gcptgw17"
  region              = "us-east1"
  cidr                = "10.17.0.0/16"
  account             = aviatrix_account.gcp.account_name
  enable_segmentation = true
  insane_mode         = true
  instance_size       = "n1-highcpu-4"
}

module "prod9" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "GCP"
  name            = "prod9"
  region          = "us-east1"
  cidr            = "10.9.0.0/16"
  account         = aviatrix_account.gcp.account_name
  transit_gw      = module.gcptgw17.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.prod.domain_name
  ha_gw           = false
}

module "dev8" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.1.0"
  cloud           = "GCP"
  name            = "dev8"
  region          = "us-east1"
  cidr            = "10.8.0.0/16"
  account         = aviatrix_account.gcp.account_name
  transit_gw      = module.gcptgw17.transit_gateway.gw_name
  security_domain = aviatrix_segmentation_security_domain.dev.domain_name
  ha_gw           = false
}