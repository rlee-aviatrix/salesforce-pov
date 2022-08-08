# Salesforce POV Terraform

## Prerequisites

- AWS Terraform provider authentication should be configured. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication
- GCP Terraform provider authentication should be configured. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication
  - Option 1: By default, the Google provider will use the `gcloud_project_credentials_filepath` file specified in `build-transit-spoke/terraform.tfvars`. If you would like to use a different file, change it in `build-transit-spoke/main.tf`:
    ```
    provider "google" {
      credentials = var.gcloud_project_credentials_filepath
    }
    ```
  - Option 2: Install `gcloud` CLI and configure authentication. The credentials option in the Google provider should be commented out if using this option.
- Increase VPC and Elastic IP quotas in us-west-2 and us-east-1.
- Subscribe to the following AMIs:
  - Aviatrix Controller: https://aws.amazon.com/marketplace/pp?sku=2ewplxno8kih1clboffpdrp9q
  - Aviatrix CoPilot: https://aws.amazon.com/marketplace/pp?sku=bjl4xsl3kdlaukmyctcb7np9s
  - Palo Alto Networks VM-Series Next-Generation Firewall (BYOL) https://aws.amazon.com/marketplace/pp?sku=6njl1pau431dv1qxipg63mvah
  - ~~Cisco Cloud Services Router (CSR) 1000V: https://aws.amazon.com/marketplace/pp?sku=5tiyrfb5tasxk9gmnab39b843~~
- An existing VPC in AWS us-east-1 with a 10.3.0.0/16 CIDR with a public subnet. In `build-transit-spoke/terraform.tfvars`, set `tableau5_vpc_id` to the VPC ID of the VPC and `tableau5_gw_subnet` to the CIDR of a public subnet in this VPC.
- Any secondary AWS accounts (such as `aws_account_name_transit_spoke`) must have IAM roles, policies and trust relationships to the primary account configured. Aviatrix provides a CloudFormation script that can automatically configure this:
  - Log into the Aviatrix controller.
  - Go to Accounts -> Access Accounts -> Select AWS if it is not selected already.
  - Scroll to Step 2 and click on the "Launch CloudFormation Script" button and run this in the secondary AWS accounts that need to be onboarded to the Aviatrix controller.

## Order To Deploy

1. build-controller-copilot
2. build-transit-spoke

## 1. build-controller-copilot

- Update values in `build-controller-copilot/terraform.tfvars`.
- If the Aviatrix IAM roles already exist in the AWS account to be used (possibly because an Aviatrix Controller was previously launched), IAM role creation can be disabled by setting `create_iam_roles` to false.
- If you don't want to deploy an Application Load Balancer, set `create_alb` to false.
- If restricting the IPs that can connect to the Aviatrix Controller in `build-controller-copilot/terraform.tfvars`, also include the VPC CIDR `10.12.0.0/16` so that the Lamba function is able to connect and intialize the Controller.
  ```
  incoming_ssl_cidr   = ["x.x.x.x/32", "10.12.0.0/16"]
  ```
- A successful deployment and intialization will have a message similar to the following in the Terraform output:
  ```
  result = "{\"status\": true, \"message\": \"Successfully initialized an Aviatrix Controller: x.x.x.x\"}"
  ```
- If the deployment fails for any reason (e.g. not subscribed to the required AMIs), fix the problems first. It is then recommended to `terraform destroy` everything and run `terraform apply` again.

## 2. build-transit-spoke

- Update values in `build-transit-spoke/terraform.tfvars`.
- For information on how to create the .json file for GCP, see https://docs.aviatrix.com/HowTos/CreateGCloudAccount.html.
- For information on Aviatrix Controller HA, see https://docs.aviatrix.com/HowTos/controller_ha.html.

## terraform destroy

- `terraform destroy` should be run in the reverse order that `terraform apply` was run:

  1. build-transit-spoke
  2. build-controller-copilot

- In build-controller-copilot, the created VPC will fail to delete. The Aviatrix Controller applies security groups to the VPC which Terraform is not aware of. The workaround is to delete the VPC from the AWS Console and then rerun `terraform destroy`.

  ```
  │ Error: error deleting EC2 VPC (vpc-0d119642abc1484fa): DependencyViolation: The vpc 'vpc-0d119642abc1484fa' has dependencies and cannot be deleted.
  │ 	status code: 400, request id: 952e8a97-2f8d-4ffa-833c-f34a47c01184
  ```

## PAN Bootstrap

- The sample `bootstrap.xml` is based on the configuration in https://docs.aviatrix.com/HowTos/config_paloaltoVM.html
- The following accounts are created:
  - Username: admin Password: Aviatrix12345#
  - Username: admin-api Password: Aviatrix12345#
  - These usernames and hashed passwords are hardcoded in `bootstrap.xml` and are not based on any of the passwords in `terraform.tfvars`.
- You can create a custom `bootstrap.xml` by following the instructions in https://docs.paloaltonetworks.com/vm-series/9-0/vm-series-deployment/bootstrap-the-vm-series-firewall/create-the-bootstrapxml-file.html
- Vendor integration assumes that the admin-api user and password is as listed. If you create a new `bootstrap.xml`, either create the same admin-api user and password or update the vendor integration resources in `build-transit-spoke/pan.tf` with the username and password that was created:

  ```
  data "aviatrix_firenet_vendor_integration" "awstgw14_fw1" {
    vpc_id      = module.awstgw14.aviatrix_firewall_instance[0].vpc_id
    instance_id = module.awstgw14.aviatrix_firewall_instance[0].instance_id
    vendor_type = "Palo Alto Networks VM-Series"
    public_ip   = module.awstgw14.aviatrix_firewall_instance[0].public_ip
    username    = "admin-api"
    password    = "Aviatrix12345#"
    save        = true
    depends_on = [
      time_sleep.wait_for_fw_instances
    ]
  }

  data "aviatrix_firenet_vendor_integration" "awstgw14_fw2" {
    vpc_id      = module.awstgw14.aviatrix_firewall_instance[1].vpc_id
    instance_id = module.awstgw14.aviatrix_firewall_instance[1].instance_id
    vendor_type = "Palo Alto Networks VM-Series"
    public_ip   = module.awstgw14.aviatrix_firewall_instance[1].public_ip
    username    = "admin-api"
    password    = "Aviatrix12345#"
    save        = true
    depends_on = [
      time_sleep.wait_for_fw_instances
    ]
  }

  data "aviatrix_firenet_vendor_integration" "gcptgw16_fw1" {
    vpc_id      = module.gcptgw16.aviatrix_firewall_instance[0].vpc_id
    instance_id = module.gcptgw16.aviatrix_firewall_instance[0].instance_id
    vendor_type = "Palo Alto Networks VM-Series"
    public_ip   = module.gcptgw16.aviatrix_firewall_instance[0].public_ip
    username    = "admin-api"
    password    = "Aviatrix12345#"
    save        = true
    depends_on = [
      time_sleep.wait_for_fw_instances
    ]
  }

  data "aviatrix_firenet_vendor_integration" "gcptgw16_fw2" {
    vpc_id = module.gcptgw16.aviatrix_firewall_instance[1].vpc_id
    instance_id = module.gcptgw16.aviatrix_firewall_instance[1].instance_id
    vendor_type = "Palo Alto Networks VM-Series"
    public_ip = module.gcptgw16.aviatrix_firewall_instance[1].public_ip
    username = "admin-api"
    password = "Aviatrix12345#"
    save = true
    depends_on = [
      time_sleep.wait_for_fw_instances
    ]
  }
  ```
