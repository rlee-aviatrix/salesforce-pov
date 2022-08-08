# Transit VPC
# Information on GCP Regions and Zones https://cloud.google.com/compute/docs/regions-zones
# GCP zones b,c are almost universally available that's why we chose them



# data "aviatrix_account" "account_id" {
#   account_name = var.account
# }



# Transit VPC
resource "aviatrix_vpc" "default" {
  count                = var.transit_use_existing_vpcs ? 0 : 1
  cloud_type           = 4
  account_name         = var.account
  name                 = local.transit_vpc_name
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = local.transit_vpc_name
    cidr   = var.transit_cidr
    region = var.region
  }
}


# Management VPC
resource "aviatrix_vpc" "management_vpc" {
  count                = var.deploy_firenet ? local.is_palo ? 1 : 0 : 0
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-mgmt"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = "${local.name}-mgmt"
    cidr   = local.mgmt_subnet_cidr
    region = var.region
  }
}

# LAN VPC 
resource "aviatrix_vpc" "lan_vpc" {
  count                = var.deploy_firenet ? 1 : 0
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-lan"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = "${local.name}-lan"
    cidr   = local.lan_subnet_cidr
    region = var.region
  }
}

# Egress VPC
resource "aviatrix_vpc" "egress_vpc" {
  count                = var.deploy_firenet ? 1 : 0
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-egress"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  subnets {
    name   = "${local.name}-egress"
    cidr   = local.egress_subnet_cidr
    region = var.region
  }
}

# BGP over LAN VPCs
resource "aviatrix_vpc" "bgp_cidrs" {
  for_each             = { for k, v in local.bgp_vpcs : k => v if var.bgp_use_existing_vpcs == false }
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-${each.key}"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  subnets {
    name   = "${local.name}-${each.key}"
    cidr   = each.value
    region = var.region
  }
}

# BGP over LAN HA VPCs
resource "aviatrix_vpc" "bgp_ha_vpc" {
  for_each             = { for k, v in local.ha_bgp_vpcs : k => v if var.bgp_use_existing_vpcs == false && contains(local.bgp_cidrs, k) == k } # Creates if the non-HA subnet is different.
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-${each.key}"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  subnets {
    name   = "${local.name}-${each.key}"
    cidr   = each.value
    region = var.region
  }
}

# Aviatrix Transit GW
resource "aviatrix_transit_gateway" "default" {
  gw_name                          = local.name
  vpc_id                           = local.transit_vpc_id
  cloud_type                       = 4
  vpc_reg                          = local.region1
  gw_size                          = local.hpe ? var.insane_instance_size : var.instance_size
  account_name                     = var.account
  subnet                           = var.transit_cidr
  insane_mode                      = local.hpe
  ha_subnet                        = var.ha_gw ? var.transit_cidr : null
  ha_gw_size                       = var.ha_gw ? (local.hpe ? var.insane_instance_size : var.instance_size) : null
  ha_zone                          = var.ha_gw ? local.region2 : null
  connected_transit                = var.connected_transit
  bgp_manual_spoke_advertise_cidrs = var.bgp_manual_spoke_advertise_cidrs
  enable_learned_cidrs_approval    = var.learned_cidr_approval
  enable_transit_firenet           = var.deploy_firenet ? true : false
  enable_segmentation              = var.enable_segmentation
  single_az_ha                     = var.single_az_ha
  single_ip_snat                   = var.single_ip_snat
  lan_vpc_id                       = var.deploy_firenet ? aviatrix_vpc.lan_vpc[0].name : null
  lan_private_subnet               = var.deploy_firenet ? aviatrix_vpc.lan_vpc[0].subnets[0].cidr : null
  enable_advertise_transit_cidr    = var.enable_advertise_transit_cidr
  bgp_polling_time                 = var.bgp_polling_time
  bgp_ecmp                         = var.bgp_ecmp
  enable_bgp_over_lan              = var.bgp_cidrs != null ? true : false
  local_as_number                  = var.bgp_asn != 0 ? var.bgp_asn : null

  #GCP BGP interfaces
  dynamic "bgp_lan_interfaces" {
    for_each = { for k, v in local.bgp_vpcs : k => v }
    content {
      vpc_id = bgp_lan_interfaces.key
      subnet = bgp_lan_interfaces.value
    }
  }

  dynamic "ha_bgp_lan_interfaces" {
    for_each = { for k, v in local.ha_bgp_vpcs : k => v }
    content {
      vpc_id = ha_bgp_lan_interfaces.key
      subnet = ha_bgp_lan_interfaces.value
    }
  }
}


# Firewall instances 
resource "aviatrix_firewall_instance" "firewall_instance" {
  count                  = var.deploy_firenet ? var.ha_gw ? 0 : 1 : 0
  firewall_name          = "${local.name}-fw"
  firewall_size          = var.fw_instance_size
  vpc_id                 = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, var.gcloud_project_id)
  firewall_image         = local.firewall_image
  firewall_image_version = local.firewall_image_version
  egress_subnet          = format("%s~~%s~~%s", aviatrix_vpc.egress_vpc[0].subnets[0].cidr, aviatrix_vpc.egress_vpc[0].subnets[0].region, aviatrix_vpc.egress_vpc[0].subnets[0].name)
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = local.is_palo ? format("%s~~%s~~%s", aviatrix_vpc.management_vpc[0].subnets[0].cidr, aviatrix_vpc.management_vpc[0].subnets[0].region, aviatrix_vpc.management_vpc[0].subnets[0].name) : null
  management_vpc_id      = local.is_palo ? aviatrix_vpc.management_vpc[0].vpc_id : null
  egress_vpc_id          = aviatrix_vpc.egress_vpc[0].vpc_id
  bootstrap_bucket_name  = var.bootstrap_bucket_name
  zone                   = local.region1
}



resource "aviatrix_firewall_instance" "firewall_instance_1" {
  count                  = var.deploy_firenet ? var.ha_gw ? 1 : 0 : 0
  firewall_name          = "${local.name}-fw1"
  firewall_size          = var.fw_instance_size
  vpc_id                 = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, var.gcloud_project_id)
  firewall_image         = local.firewall_image
  firewall_image_version = local.firewall_image_version
  egress_subnet          = format("%s~~%s~~%s", aviatrix_vpc.egress_vpc[0].subnets[0].cidr, aviatrix_vpc.egress_vpc[0].subnets[0].region, aviatrix_vpc.egress_vpc[0].subnets[0].name)
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = local.is_palo ? format("%s~~%s~~%s", aviatrix_vpc.management_vpc[0].subnets[0].cidr, aviatrix_vpc.management_vpc[0].subnets[0].region, aviatrix_vpc.management_vpc[0].subnets[0].name) : null
  management_vpc_id      = local.is_palo ? aviatrix_vpc.management_vpc[0].vpc_id : null
  egress_vpc_id          = aviatrix_vpc.egress_vpc[0].vpc_id
  bootstrap_bucket_name  = var.bootstrap_bucket_name
  zone                   = var.ha_gw ? local.region1 : null
}

resource "aviatrix_firewall_instance" "firewall_instance_2" {
  count                  = var.deploy_firenet ? var.ha_gw ? 1 : 0 : 0
  firewall_name          = "${local.name}-fw2"
  firewall_size          = var.fw_instance_size
  vpc_id                 = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, var.gcloud_project_id)
  firewall_image         = local.firewall_image
  firewall_image_version = local.firewall_image_version
  egress_subnet          = format("%s~~%s~~%s", aviatrix_vpc.egress_vpc[0].subnets[0].cidr, aviatrix_vpc.egress_vpc[0].subnets[0].region, aviatrix_vpc.egress_vpc[0].subnets[0].name)
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = local.is_palo ? format("%s~~%s~~%s", aviatrix_vpc.management_vpc[0].subnets[0].cidr, aviatrix_vpc.management_vpc[0].subnets[0].region, aviatrix_vpc.management_vpc[0].subnets[0].name) : null
  management_vpc_id      = local.is_palo ? aviatrix_vpc.management_vpc[0].vpc_id : null
  egress_vpc_id          = aviatrix_vpc.egress_vpc[0].vpc_id
  bootstrap_bucket_name  = var.bootstrap_bucket_name
  zone                   = var.ha_gw ? local.region2 : null
}

# Firenet
resource "aviatrix_firenet" "firenet" {
  count                                = var.deploy_firenet ? 1 : 0
  vpc_id                               = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, var.gcloud_project_id)
  inspection_enabled                   = var.inspection_enabled
  egress_enabled                       = var.egress_enabled
  manage_firewall_instance_association = false
  east_west_inspection_excluded_cidrs  = var.east_west_inspection_excluded_cidrs
  depends_on                           = [aviatrix_firewall_instance_association.firenet_instance, aviatrix_firewall_instance_association.firenet_instance1, aviatrix_firewall_instance_association.firenet_instance2]
}


resource "aviatrix_firewall_instance_association" "firenet_instance" {
  count                = var.ha_gw ? 0 : 1
  vpc_id               = aviatrix_firewall_instance.firewall_instance[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance[0].egress_interface
  attached             = var.attached
}

resource "aviatrix_firewall_instance_association" "firenet_instance1" {
  count                = var.deploy_firenet ? var.ha_gw ? 1 : 0 : 0
  vpc_id               = aviatrix_firewall_instance.firewall_instance_1[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_1[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance_1[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_1[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_1[0].egress_interface
  attached             = var.attached
}

resource "aviatrix_firewall_instance_association" "firenet_instance2" {
  count                = var.deploy_firenet ? var.ha_gw ? 1 : 0 : 0
  vpc_id               = aviatrix_firewall_instance.firewall_instance_2[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_2[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance_2[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_2[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_2[0].egress_interface
  attached             = var.attached
}
