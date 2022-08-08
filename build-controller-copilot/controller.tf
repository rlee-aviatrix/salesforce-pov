module "aviatrix-iam-roles" {
  count         = var.create_iam_roles ? 1 : 0
  source        = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles"
  ec2_role_name = var.ec2_role_name
  app_role_name = var.app_role_name
}

module "aviatrix-controller-build" {
  source                 = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-build"
  vpc                    = aws_vpc.vpc.id
  subnet                 = aws_subnet.subnet.id
  controller_name        = var.controller_name
  keypair                = var.keypair
  ec2role                = var.ec2_role_name
  incoming_ssl_cidr      = var.incoming_ssl_cidr
  root_volume_size       = 64
  type                   = "MeteredPlatinumCopilot"
  termination_protection = "false" # Set to true for production
  depends_on = [
    aws_key_pair.keypair
  ]
}

module "aviatrix-controller-initialize" {
  source              = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-initialize"
  admin_email         = var.admin_email
  admin_password      = var.admin_password
  private_ip          = module.aviatrix-controller-build.private_ip
  public_ip           = module.aviatrix-controller-build.public_ip
  access_account_name = var.access_account_name
  aws_account_id      = var.aws_account_id
  vpc_id              = aws_vpc.vpc.id
  subnet_id           = aws_subnet.subnet.id
  ec2_role_name       = var.ec2_role_name
  app_role_name       = var.app_role_name
}