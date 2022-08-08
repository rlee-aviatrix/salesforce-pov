# module "hpe1" {
#   source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
#   version         = "1.1.0"
#   cloud           = "AWS"
#   name            = "hpe1"
#   region          = "us-east-1"
#   cidr            = "192.168.1.0/24"
#   account         = var.aws_account_name
#   transit_gw      = module.awstgw14.transit_gateway.gw_name
#   security_domain = aviatrix_segmentation_security_domain.prod.domain_name
#   instance_size   = "c5n.18xlarge"
#   insane_mode     = true
# }

# module "hpe2" {
#   source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
#   version         = "1.1.0"
#   cloud           = "AWS"
#   name            = "hpe2"
#   region          = "us-east-1"
#   cidr            = "192.168.2.0/24"
#   account         = var.aws_account_name
#   transit_gw      = module.awstgw14.transit_gateway.gw_name
#   security_domain = aviatrix_segmentation_security_domain.prod.domain_name
#   instance_size   = "c5n.18xlarge"
#   insane_mode     = true
# }

# module "hpe3" {
#   source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
#   version         = "1.1.0"
#   cloud           = "GCP"
#   name            = "hpe3"
#   region          = "us-west1"
#   cidr            = "192.168.3.0/24"
#   account         = aviatrix_account.gcp.account_name
#   transit_gw      = module.gcptgw16.transit_gateway.gw_name
#   security_domain = aviatrix_segmentation_security_domain.prod.domain_name
#   instance_size   = "n1-highcpu-32"
#   insane_mode     = true
# }

# module "hpe4" {
#   source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
#   version         = "1.1.0"
#   cloud           = "GCP"
#   name            = "hpe4"
#   region          = "us-west1"
#   cidr            = "192.168.4.0/24"
#   account         = aviatrix_account.gcp.account_name
#   transit_gw      = module.gcptgw16.transit_gateway.gw_name
#   security_domain = aviatrix_segmentation_security_domain.prod.domain_name
#   instance_size   = "n1-highcpu-32"
#   insane_mode     = true
# }