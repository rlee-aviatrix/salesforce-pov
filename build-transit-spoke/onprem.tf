# provider "aws" {
#   alias  = "us-east-1"
#   region = "us-east-1"
# }

# resource "aws_vpc" "onprem_vpc" {
#   provider   = aws.us-east-1
#   cidr_block = "10.18.0.0/16"
#   tags = {
#     Name = "onprem"
#   }
# }

# resource "aws_subnet" "onprem_subnet" {
#   provider   = aws.us-east-1
#   vpc_id     = aws_vpc.onprem_vpc.id
#   cidr_block = "10.18.0.0/24"
#   tags = {
#     Name = "onprem-subnet"
#   }
# }

# resource "aws_internet_gateway" "onprem_igw" {
#   provider = aws.us-east-1
#   vpc_id   = aws_vpc.onprem_vpc.id
#   tags = {
#     Name = "onprem-igw"
#   }
# }

# resource "aws_route_table" "onprem_rtb" {
#   provider = aws.us-east-1
#   vpc_id   = aws_vpc.onprem_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.onprem_igw.id
#   }
#   tags = {
#     Name = "onprem-rtb"
#   }
# }

# resource "aws_route_table_association" "onprem_rtb_association" {
#   provider       = aws.us-east-1
#   subnet_id      = aws_subnet.onprem_subnet.id
#   route_table_id = aws_route_table.onprem_rtb.id
# }


# resource "aws_security_group" "onprem_sg" {
#   provider = aws.us-east-1
#   name     = "csr0-security-group"
#   vpc_id   = aws_vpc.onprem_vpc.id
#   tags = {
#     Name = "onprem-security-group"
#   }
# }

# resource "aws_security_group_rule" "onprem_inbound" {
#   provider          = aws.us-east-1
#   type              = "ingress"
#   protocol          = "-1"
#   from_port         = 0
#   to_port           = 0
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.onprem_sg.id
# }

# resource "aws_security_group_rule" "onprem_outbound" {
#   provider          = aws.us-east-1
#   type              = "egress"
#   protocol          = "-1"
#   from_port         = 0
#   to_port           = 0
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.onprem_sg.id
# }

# resource "aws_network_interface" "onprem_nic" {
#   provider          = aws.us-east-1
#   subnet_id         = aws_subnet.onprem_subnet.id
#   security_groups   = [aws_security_group.onprem_sg.id]
#   source_dest_check = false
#   tags = {
#     Name = "onprem-nic"
#   }
# }

# resource "aws_eip" "onprem_eip" {
#   provider = aws.us-east-1
#   vpc      = true
#   tags = {
#     Name = "onprem-eip"
#   }
# }

# resource "aws_eip_association" "onprem_eip_association" {
#   provider             = aws.us-east-1
#   network_interface_id = aws_network_interface.onprem_nic.id
#   allocation_id        = aws_eip.onprem_eip.id
#   depends_on = [
#     aws_instance.onprem_csr
#   ]
# }

# resource "aws_instance" "onprem_csr" {
#   provider      = aws.us-east-1
#   ami           = "ami-0d18f295f92eaca4c"
#   instance_type = "t2.medium"
#   network_interface {
#     network_interface_id = aws_network_interface.onprem_nic.id
#     device_index         = 0
#   }
#   user_data = templatefile("${path.module}/csr/onprem.txt",
#     {
#       onprem_csr_hostname  = "onpremcsr"
#       onprem_csr_username  = var.onprem_csr_username
#       onprem_csr_password  = var.onprem_csr_password
#       onprem_csr_public_ip = aws_eip.onprem_eip.public_ip
#       pre_shared_key       = var.onprem_csr_password
#       transits = [
#         {
#           ip                   = module.awstgw13.transit_gateway.eip
#           ha_ip                = module.awstgw13.transit_gateway.ha_eip
#           index_number         = "13"
#           aviatrix_bgp_asn     = "64773"
#           onprem_tunnel_ip_1   = "169.254.13.1"
#           onprem_tunnel_ip_2   = "169.254.13.5"
#           aviatrix_tunnel_ip_1 = "169.254.13.2"
#           aviatrix_tunnel_ip_2 = "169.254.13.6"
#         },
#         {
#           ip                   = module.awstgw14.transit_gateway.eip
#           ha_ip                = module.awstgw14.transit_gateway.ha_eip
#           index_number         = "14"
#           aviatrix_bgp_asn     = "64774"
#           onprem_tunnel_ip_1   = "169.254.14.1"
#           onprem_tunnel_ip_2   = "169.254.14.5"
#           aviatrix_tunnel_ip_1 = "169.254.14.2"
#           aviatrix_tunnel_ip_2 = "169.254.14.6"
#         },
#         {
#           ip                   = module.awstgw15.transit_gateway.eip
#           ha_ip                = module.awstgw15.transit_gateway.ha_eip
#           index_number         = "15"
#           aviatrix_bgp_asn     = "64775"
#           onprem_tunnel_ip_1   = "169.254.15.1"
#           onprem_tunnel_ip_2   = "169.254.15.5"
#           aviatrix_tunnel_ip_1 = "169.254.15.2"
#           aviatrix_tunnel_ip_2 = "169.254.15.6"
#         },
#         {
#           ip                   = module.gcptgw16.transit_gateway.eip
#           ha_ip                = module.gcptgw16.transit_gateway.ha_eip
#           index_number         = "16"
#           aviatrix_bgp_asn     = "64776"
#           onprem_tunnel_ip_1   = "169.254.16.1"
#           onprem_tunnel_ip_2   = "169.254.16.5"
#           aviatrix_tunnel_ip_1 = "169.254.16.2"
#           aviatrix_tunnel_ip_2 = "169.254.16.6"
#         },
#         # {
#         #   ip                   = module.gcptgw17.transit_gateway.eip
#         #   ha_ip                = module.gcptgw17.transit_gateway.ha_eip
#         #   index_number         = "17"
#         #   aviatrix_bgp_asn     = "64777"
#         #   onprem_tunnel_ip_1   = "169.254.17.1"
#         #   onprem_tunnel_ip_2   = "169.254.17.5"
#         #   aviatrix_tunnel_ip_1 = "169.254.17.2"
#         #   aviatrix_tunnel_ip_2 = "169.254.17.6"
#         # }
#       ]
#     }
#   )
#   tags = {
#     Name = "onprem-csr"
#   }
# }

# resource "aviatrix_transit_external_device_conn" "awstgw13_onprem" {
#   vpc_id                   = module.awstgw13.vpc.vpc_id
#   connection_name          = "awstgw13-onprem"
#   gw_name                  = module.awstgw13.transit_gateway.gw_name
#   connection_type          = "bgp"
#   bgp_local_as_num         = "64773"
#   bgp_remote_as_num        = "64778"
#   remote_gateway_ip        = aws_eip.onprem_eip.public_ip
#   local_tunnel_cidr        = "169.254.13.2/30,169.254.13.6/30"
#   remote_tunnel_cidr       = "169.254.13.1/30,169.254.13.5/30"
#   phase1_remote_identifier = [aws_network_interface.onprem_nic.private_ip]
#   pre_shared_key           = var.onprem_csr_password
# }

# resource "aviatrix_transit_external_device_conn" "awstgw14_onprem" {
#   vpc_id                   = module.awstgw14.vpc.vpc_id
#   connection_name          = "awstgw14-onprem"
#   gw_name                  = module.awstgw14.transit_gateway.gw_name
#   connection_type          = "bgp"
#   bgp_local_as_num         = "64774"
#   bgp_remote_as_num        = "64778"
#   remote_gateway_ip        = aws_eip.onprem_eip.public_ip
#   local_tunnel_cidr        = "169.254.14.2/30,169.254.14.6/30"
#   remote_tunnel_cidr       = "169.254.14.1/30,169.254.14.5/30"
#   phase1_remote_identifier = [aws_network_interface.onprem_nic.private_ip]
#   pre_shared_key           = var.onprem_csr_password
# }

# resource "aviatrix_transit_external_device_conn" "awstgw15_onprem" {
#   vpc_id                   = module.awstgw15.vpc.vpc_id
#   connection_name          = "awstgw15-onprem"
#   gw_name                  = module.awstgw15.transit_gateway.gw_name
#   connection_type          = "bgp"
#   bgp_local_as_num         = "64775"
#   bgp_remote_as_num        = "64778"
#   remote_gateway_ip        = aws_eip.onprem_eip.public_ip
#   local_tunnel_cidr        = "169.254.15.2/30,169.254.15.6/30"
#   remote_tunnel_cidr       = "169.254.15.1/30,169.254.15.5/30"
#   phase1_remote_identifier = [aws_network_interface.onprem_nic.private_ip]
#   pre_shared_key           = var.onprem_csr_password
# }

# resource "aviatrix_transit_external_device_conn" "gcptgw16_onprem" {
#   vpc_id                   = join("", [module.gcptgw16.vpc.vpc_id, "~-~", var.gcloud_project_id_transit])
#   connection_name          = "gcptgw16-onprem"
#   gw_name                  = module.gcptgw16.transit_gateway.gw_name
#   connection_type          = "bgp"
#   bgp_local_as_num         = "64776"
#   bgp_remote_as_num        = "64778"
#   remote_gateway_ip        = aws_eip.onprem_eip.public_ip
#   local_tunnel_cidr        = "169.254.16.2/30,169.254.16.6/30"
#   remote_tunnel_cidr       = "169.254.16.1/30,169.254.16.5/30"
#   phase1_remote_identifier = [aws_network_interface.onprem_nic.private_ip]
#   pre_shared_key           = var.onprem_csr_password
# }

# resource "aviatrix_transit_external_device_conn" "gcptgw17_onprem" {
#   vpc_id                   = join("", [module.gcptgw17.vpc.vpc_id, "~-~", var.gcloud_project_id_transit])
#   connection_name          = "gcptgw17-onprem"
#   gw_name                  = module.gcptgw17.transit_gateway.gw_name
#   connection_type          = "bgp"
#   bgp_local_as_num         = "64777"
#   bgp_remote_as_num        = "64778"
#   remote_gateway_ip        = aws_eip.onprem_eip.public_ip
#   local_tunnel_cidr        = "169.254.17.2/30,169.254.17.6/30"
#   remote_tunnel_cidr       = "169.254.17.1/30,169.254.17.5/30"
#   phase1_remote_identifier = [aws_network_interface.onprem_nic.private_ip]
#   pre_shared_key           = var.onprem_csr_password
# }
