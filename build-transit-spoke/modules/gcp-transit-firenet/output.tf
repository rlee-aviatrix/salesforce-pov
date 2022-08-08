output "transit_vpc" {
  description = "The created Transit VPC with all of it's attributes"
  value       = aviatrix_vpc.default
}

output "egress_vpc" {
  description = "The created Egress VPC with all of it's attributes"
  value       = var.deploy_firenet ? aviatrix_vpc.egress_vpc : null
}


output "management_vpc" {
  description = "The created Management VPC with all of it's attributes"
  value       = var.deploy_firenet ? aviatrix_vpc.management_vpc : null
}


output "lan_vpc" {
  description = "The created LAN VPC with all of it's attributes"
  value       = var.deploy_firenet ? aviatrix_vpc.lan_vpc : null
}

output "transit_gateway" {
  description = "The Aviatrix transit gateway object with all of it's attributes"
  value       = aviatrix_transit_gateway.default
}

output "aviatrix_firenet" {
  description = "The Aviatrix firenet object with all of it's attributes"
  value       = var.deploy_firenet ? aviatrix_firenet.firenet : null
}

output "aviatrix_firewall_instance" {
  description = "A list with the created firewall instances and their attributes"
  value       = var.deploy_firenet ? var.ha_gw ? [aviatrix_firewall_instance.firewall_instance_1[0], aviatrix_firewall_instance.firewall_instance_2[0]] : [aviatrix_firewall_instance.firewall_instance[0]] : null
}