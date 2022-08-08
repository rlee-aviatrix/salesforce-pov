variable "admin_email" {
  type = string
}

variable "controller_name" {
  type = string
}

variable "aws_account_name" {
  type = string
}

variable "ec2_role_name" {
  type = string
}

variable "app_role_name" {
  type = string
}

variable "aws_account_name_transit_spoke" {
  type = string
}

variable "aws_account_id_transit_spoke" {
  type = string
}

variable "aws_account_name_ma" {
  type = string
}

variable "aws_account_id_ma" {
  type = string
}

variable "gcp_account_name" {
  type = string
}

variable "gcloud_project_id" {
  type = string
}

variable "gcloud_project_credentials_filepath" {
  type = string
}

variable "aviatrix_controller_ip" {
  type = string
}

variable "aviatrix_username" {
  type = string
}

variable "aviatrix_password" {
  type = string
}

variable "aviatrix_copilot_ip" {
  type = string
}

variable "tableau5_vpc_id" {
  type = string
}

variable "tableau5_gw_subnet" {
  type = string
}

variable "mna19_tgw_ip1" {
  type = string
}

variable "mna19_tgw_ip2" {
  type = string
}

variable "mna19_tgw_psk1" {
  type = string
}

variable "mna19_tgw_psk2" {
  type = string
}

variable "mna19_tgw_nat" {
  type = map(string)
  default = {
    remote_subnet_cidr    = "10.3.0.0/16",
    remote_subnet_virtual = "172.24.0.0/16",
    local_subnet_cidr     = "10.0.0.0/13",
    local_subnet_virtual  = "172.16.0.0/13",
  }
}

# variable "onprem_csr_username" {
#   type = string
# }

# variable "onprem_csr_password" {
#   type = string
# }