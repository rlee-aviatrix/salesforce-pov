variable "spoke_gw_object" {
  description = "Aviatrix Spoke Gateway object with all of it's attributes."
}

variable "spoke_cidrs" {
  description = "VNET or VPC CIDRs (typically one, but can be multiple)"
}

variable "transit_gw_name" {
  description = "Name of the transit gateway, to determine the connection for SNAT rule."
}

variable "gw1_snat_addr" {
  description = "IP Address to be used for hide natting traffic sourced from the spoke VNET/VPC"
}

variable "gw2_snat_addr" {
  description = "IP Address to be used for hide natting traffic sourced from the spoke VNET/VPC. Required when spoke is HA pair."
  default     = ""
}

variable "uturnnat" {
  description = "Make the DNAT IP reachable inside the spoke VNET/VPC through U-Turn NAT"
  default     = false
}

variable "dnat_rules" {
  description = "Contains the properties to create the DNAT rules. When left empty, only SNAT for traffic initiated from the spoke VNET/VPC is configured."
  type        = map(any)
  default = {
    dummy = {
      dst_cidr  = "0.0.0.0/0",
      dst_port  = "80",
      protocol  = "tcp",
      dnat_ips  = "0.0.0.0",
      dnat_port = "80",
    }
  }
}

variable "ha_gw" {
  description = "Specify whether the spoke has an HA gateway."
  type = bool
  default = false
}
