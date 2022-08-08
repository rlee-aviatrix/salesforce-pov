variable "region" {
  description = "Primary GCP region where subnet and Aviatrix Transit Gateway will be created"
  type        = string
}

variable "account" {
  description = "Name of the GCP Access Account defined in the Aviatrix Controller"
  type        = string
}

variable "instance_size" {
  description = "Size of the compute instance for the Aviatrix Gateways"
  default     = "n1-standard-1"
  type        = string
}


variable "insane_instance_size" {
  description = "Size of the compute instance for the Aviatrix Gateways"
  default     = "n1-highcpu-4"
  type        = string
}

variable "fw_instance_size" {
  description = "Size of the compute instance for the Aviatrix Gateways"
  default     = "n1-standard-4"
  type        = string
}

variable "transit_cidr" {
  description = "CIDR of the GCP transit subnet"
  type        = string
}

variable "transit_vpc_name" {
  description = "Name of Transit VPC."
  type        = string
  default     = ""
}

variable "firewall_cidr" {
  description = "CIDR to derive Firenet CIDR ranges"
  type        = string
  default     = ""
}

variable "ha_gw" {
  description = "Set to false te deploy a single transit GW"
  type        = bool
  default     = true
}

variable "az1" {
  description = "Concatenates with region to form az names. e.g. us-east1b."
  type        = string
  default     = "b"
}

variable "az2" {
  description = "Concatenates with region or ha_region (depending whether ha_region is set) to form az names. e.g. us-east1c."
  type        = string
  default     = "c"
}

variable "name" {
  description = "Name for this transit VPC and it's gateways"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Boolean to determine if name will be prepended with avx-"
  type        = bool
  default     = false
}

variable "suffix" {
  description = "Boolean to determine if name will be appended with -transit"
  type        = bool
  default     = false
}

variable "connected_transit" {
  description = "Set to false to disable connected transit."
  type        = bool
  default     = true
}

variable "bgp_manual_spoke_advertise_cidrs" {
  description = "Define a list of CIDRs that should be advertised via BGP."
  type        = string
  default     = ""
}

variable "learned_cidr_approval" {
  description = "Set to true to enable learned CIDR approval."
  type        = string
  default     = "false"
}

variable "east_west_inspection_excluded_cidrs" {
  description = "Network List Excluded From East-West Inspection."
  type        = list(string)
  default     = null
}

variable "hpe" {
  description = "Boolean to enable insane mode"
  type        = bool
  default     = false
}

variable "enable_segmentation" {
  description = "Switch to true to enable transit segmentation"
  type        = bool
  default     = false
}

variable "single_az_ha" {
  description = "Set to true if Controller managed Gateway HA is desired"
  type        = bool
  default     = true
}

variable "single_ip_snat" {
  description = "Enable single_ip mode Source NAT for this container"
  type        = bool
  default     = false
}

variable "enable_advertise_transit_cidr" {
  description = "Switch to enable/disable advertise transit VPC network CIDR for a VGW connection"
  type        = bool
  default     = false
}

variable "bgp_polling_time" {
  description = "BGP route polling time. Unit is in seconds"
  type        = string
  default     = "50"
}

variable "bgp_ecmp" {
  description = "Enable Equal Cost Multi Path (ECMP) routing for the next hop"
  type        = bool
  default     = false
}

variable "firewall_image" {
  description = "The firewall image to be used to deploy the NGFW's. If not specified, firewalls are not deployed"
  type        = string
  default     = ""

  validation {
    condition     = length(split("~", var.firewall_image)) == 2 || var.firewall_image == ""
    error_message = "The image must be specified as <firewall image name>~<version>. To disable Firenet, do not specify the variable."
  }
}

variable "egress_enabled" {
  description = "Set to true to enable egress inspection on the firewall instances"
  type        = bool
  default     = false
}

variable "inspection_enabled" {
  description = "Set to false to disable inspection on the firewall instances"
  type        = bool
  default     = true
}


variable "attached" {
  description = "Boolean to determine if the spawned firewall instances will be attached on creation"
  type        = bool
  default     = true
}

variable "bootstrap_bucket_name" {
  description = "The firewall bootstrap bucket name"
  type        = string
  default     = null
}

variable "bgp_cidrs" {
  description = "CIDRs for BGP over LAN VPCs. If the GW and HAGW need to be in separate VPCs, then specify both CIDRs like 10.0.0.0/28~10.0.0.16/28."
  type        = list(string)
  default     = null
}

variable "bgp_names" {
  description = "Names of BGP over LAN VPCs. If the GW and HAGW need to be in separate VPCs, then specify both names like vpc-a~vpc-b. This list must correspond exactly with variable bgp_cidrs. This is required for using existing VPCs."
  type        = list(string)
  default     = null
}

variable "bgp_use_existing_vpcs" {
  description = "Create VPCs for BGP?"
  type        = bool
  default     = false
}

variable "transit_use_existing_vpcs" {
  description = "Create VPCs for Transit?"
  type        = bool
  default     = false
}

# variable "firenet_use_existing_vpcs" {
#    description = "Create VPCs for firenet?"
#    type        = bool
#    default     = false
#  }

variable "bgp_asn" {
  description = "BGP ASN for Transit Gateway"
  type        = number
  default     = 0
}

variable "deploy_firenet" {
  description = "Set to false to deploy Transit only."
  type        = bool
  default     = true
}

variable "gcloud_project_id" {
  description = "GCP Project ID"
  type        = string
}

locals {
  is_palo                = var.deploy_firenet ? length(regexall("palo", lower(var.firewall_image))) > 0 : null #Check if fw image contains palo. Needs special handling for management_subnet (CP & Fortigate null)
  lower_name             = length(var.name) > 0 ? replace(lower(var.name), " ", "-") : replace(lower(var.region), " ", "-")
  prefix                 = var.prefix ? "avx-" : ""
  suffix                 = var.suffix ? "-transit" : ""
  name                   = "${local.prefix}${local.lower_name}${local.suffix}"
  cidrbits               = tonumber(split("/", var.transit_cidr)[1])
  newbits                = 26 - local.cidrbits
  netnum                 = pow(2, local.newbits)
  lan_subnet_cidr        = var.deploy_firenet ? cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 4) : null
  egress_subnet_cidr     = var.deploy_firenet ? cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 2) : null
  mgmt_subnet_cidr       = var.deploy_firenet ? cidrsubnet(var.firewall_cidr, local.newbits, local.netnum - 3) : null
  region1                = "${var.region}-${var.az1}"
  region2                = "${var.region}-${var.az2}"
  hpe                    = var.hpe || var.bgp_cidrs != null ? true : false
  firewall_image         = var.deploy_firenet ? element(split("~", var.firewall_image), 0) : null
  firewall_image_version = var.deploy_firenet ? element(split("~", var.firewall_image), 1) : null
  transit_vpc_name       = var.transit_vpc_name != "" ? var.transit_vpc_name : local.name
  transit_vpc_id         = try(aviatrix_vpc.default[0].name, local.transit_vpc_name)
  new_bgp_names          = var.bgp_cidrs != null && var.bgp_names == null ? [for cidr in var.bgp_cidrs : length(split("~", cidr)) == 1 ? "bgp-${index(var.bgp_cidrs, cidr) + 1}~bgpha-${index(var.bgp_cidrs, cidr) + 1}" : "bgp-${index(var.bgp_cidrs, cidr) + 1}~bgp-${index(var.bgp_cidrs, cidr) + 1}"] : null
  existing_bgp_names     = var.bgp_cidrs != null && var.bgp_names != null ? [for name in var.bgp_names : length(split("~", name)) == 1 ? "${name}~${name}" : name] : null
  bgp_cidrs              = var.bgp_cidrs != null ? [for cidr in var.bgp_cidrs : length(split("~", cidr)) == 1 ? "${cidr}~${cidr}" : cidr] : []
  bgp_names              = local.new_bgp_names != null ? local.new_bgp_names : local.existing_bgp_names != null ? local.existing_bgp_names : null
  bgp_vpcs               = local.bgp_cidrs != [] ? local.bgp_names != null ? zipmap([for name in local.bgp_names : element(split("~", name), 0)], [for cidr in local.bgp_cidrs : element(split("~", cidr), 0)]) : {} : {}
  ha_bgp_vpcs            = local.bgp_cidrs != [] ? local.bgp_names != null ? zipmap([for name in local.bgp_names : element(split("~", name), 1)], [for cidr in local.bgp_cidrs : element(split("~", cidr), 1)]) : {} : {}
}
