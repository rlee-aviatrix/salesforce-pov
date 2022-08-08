admin_email                         = "changeme@example.com"
controller_name                     = "SalesforceAviatrixController"
aws_account_name                    = "Salesforce-AWS" # This needs to match the access_account_name specified in build-controller-copilot
ec2_role_name                       = "aviatrix-role-ec2"
app_role_name                       = "aviatrix-role-app"
aws_account_name_transit_spoke      = "Salesforce-AWS-Transit-Spoke"
aws_account_id_transit_spoke        = "222222222222"
aws_account_name_ma                 = "Salesforce-AWS-MA"
aws_account_id_ma                   = "333333333333"
gcp_account_name                    = "Salesforce-GCP-Transit-Spoke"
gcloud_project_id                   = "rlee-01"
gcloud_project_credentials_filepath = "/Users/ronaldlee/Desktop/gcp-credentials/gcp-rlee-01.json"
aviatrix_controller_ip              = "52.89.28.150"
aviatrix_username                   = "admin"
aviatrix_password                   = "Aviatrix12345#"
aviatrix_copilot_ip                 = "44.233.253.184"
tableau5_vpc_id                     = "vpc-01234567890123456"
tableau5_gw_subnet                  = "10.3.0.0/20"
mna19_tgw_ip1                       = "1.1.1.1"
mna19_tgw_ip2                       = "1.1.1.1"
mna19_tgw_psk1                      = "Aviatrix12345#"
mna19_tgw_psk2                      = "Aviatrix12345#"
# onprem_csr_username                 = "salesforceadmin"
# onprem_csr_password                 = "Aviatrix12345#"