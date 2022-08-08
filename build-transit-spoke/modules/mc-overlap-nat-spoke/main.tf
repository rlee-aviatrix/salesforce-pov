resource "aviatrix_gateway_snat" "gw_1" {
  gw_name    = var.spoke_gw_object.gw_name
  sync_to_ha = false
  snat_mode  = "customized_snat"

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = snat_policy.value
      dst_cidr   = "0.0.0.0/0"
      connection = var.transit_gw_name
      protocol   = "all"
      snat_ips   = var.gw1_snat_addr
    }
  }

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.spoke_gw_object.private_ip
    }
  }
}

resource "aviatrix_gateway_snat" "gw_2" {
  count      = var.ha_gw ? 1 : 0
  gw_name    = var.ha_gw ? var.spoke_gw_object.ha_gw_name : "dummy"
  sync_to_ha = false
  snat_mode  = "customized_snat"

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = snat_policy.value
      dst_cidr   = "0.0.0.0/0"
      connection = var.transit_gw_name
      protocol   = "all"
      snat_ips   = var.gw2_snat_addr
    }
  }

  dynamic "snat_policy" {
    for_each = { for cidr in var.spoke_cidrs : cidr => cidr }
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = snat_policy.value
      connection = "None"
      interface  = "eth0"
      protocol   = "all"
      snat_ips   = var.ha_gw ? var.spoke_gw_object.ha_private_ip : "1.1.1.1"
    }
  }
}

resource "aviatrix_gateway_dnat" "dnat_rules" {
  count      = contains(keys(var.dnat_rules), "dummy") ? 0 : 1
  gw_name    = var.spoke_gw_object.gw_name
  sync_to_ha = true

  dynamic "dnat_policy" {
    for_each = var.dnat_rules
    content {
      src_cidr   = "0.0.0.0/0"
      dst_cidr   = dnat_policy.value.dst_cidr
      dst_port   = dnat_policy.value.dst_port
      protocol   = dnat_policy.value.protocol
      dnat_ips   = dnat_policy.value.dnat_ips
      dnat_port  = dnat_policy.value.dnat_port
      connection = var.transit_gw_name
    }
  }

  dynamic "dnat_policy" {
    for_each = var.uturnnat ? var.dnat_rules : {} #Only create DNAT policy for U-Turn NAT if turned on
    content {
      src_cidr  = "0.0.0.0/0"
      dst_cidr  = dnat_policy.value.dst_cidr
      dst_port  = dnat_policy.value.dst_port
      protocol  = dnat_policy.value.protocol
      dnat_ips  = dnat_policy.value.dnat_ips
      dnat_port = dnat_policy.value.dnat_port
      interface = "eth0"
    }
  }
}
