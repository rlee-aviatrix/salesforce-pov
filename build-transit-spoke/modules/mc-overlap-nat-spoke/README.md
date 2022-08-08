# terraform-aviatrix-mc-overlap-nat-spoke

### Description
This configures Aviatrix spoke gateways to deal with IP overlap in the spoke VNET/VPC by adding NAT rules and route propagation.
The actual spoke gateway deployment happens outside of this module. It can be combined with the Aviatrix spoke deployment modules.

This module uses hide-nat (Source-NAT, SNAT) to hide all traffic initiated from the spoke VNET/VPC behind a unique gateway IP address.
In order to expose services hosted inside the VNET/VPC to the outside world, a combination of destination NAT (DNAT) and SNAT is used.

Make sure to include gw1_snat_addr, gw2_snat_addr and any dst_cidr's in the dnat rules in the spoke gateway included_advertised_spoke_routes attribute.

### Diagram
<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-overlap-nat-spoke/blob/master/img/terraform-aviatrix-mc-overlap-nat-spoke.png?raw=true">

### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.2 | 0.13-1.0.1 | >=6.4 | >=0.2.19
v1.0.1 | 0.13-1.0.1 | >=6.4 | >=0.2.19
v1.0.0 | 0.13-1.0.1 | >=6.4 | >=0.2.19

### Usage Example
```
module "spoke1_nat" {
  source  = "terraform-aviatrix-modules/mc-overlap-nat-spoke/aviatrix"
  version = "1.0.2"

  #Tip, use count on the module to create or destroy the NAT rules based on spoke gateway attachement
  #Example: count = var.attached ? 1 : 0 #Deploys the module only if var.attached is true.

  spoke_gw_object = data.aviatrix_spoke_gateway.spoke1
  spoke_cidrs = ["172.31.0.0/20",]
  transit_gw_name = "avx-transit-gw"
  gw1_snat_addr = "10.255.1.1"
  gw2_snat_addr = "10.255.1.2"
  dnat_rules = {
      rule1 = {
          dst_cidr = "10.255.255.1/32",
          dst_port = "80",
          protocol = "tcp",
          dnat_ips = "172.31.16.4",
          dnat_port = "80",
      },
      rule2 = {
          dst_cidr = "10.255.255.1/32",
          dst_port = "8443",
          protocol = "tcp",
          dnat_ips = "172.31.16.4",
          dnat_port = "443",
      },      
      rule3 = {
          dst_cidr = "10.255.255.2/32",
          dst_port = "80",
          protocol = "tcp",
          dnat_ips = "172.31.16.5",
          dnat_port = "80",
      },           
  }
}
```

### Variables
The following variables are required:

key | value
:--- | :---
spoke_gw_object | The Aviatrix spoke gateway object with all attributes
spoke_cidrs | VNET or VPC CIDRs (typically one, but can be multiple)
transit_gw_name | Name of the transit gateway, to determine the connection for SNAT rule.
gw1_snat_addr | IP Address to be used for hide natting traffic sourced from the spoke VNET/VPC

The following variables are optional:

key | default | value 
:---|:---|:---
gw2_snat_addr | | IP Address to be used for hide natting traffic sourced from the spoke VNET/VPC. Required when spoke is HA pair.
dnat_rules | | Contains the properties to create the DNAT rules. When left empty, only SNAT for traffic initiated from the spoke VNET/VPC is configured. Create as many unique rules as you like.
uturnnat | false | Set to true to also make the DNAT IP reachable inside the spoke VNET/VPC through U-Turn NAT.

### Outputs
This module will return the following outputs:

key | description
:---|:---
\<keyname> | \<description of object that will be returned in this output>
