variable "admin_email" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "access_account_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "incoming_ssl_cidr" {
  type = list(any)
}

variable "create_iam_roles" {
  type = bool
}

variable "ec2_role_name" {
  type = string
}

variable "app_role_name" {
  type = string
}

variable "controller_name" {
  type = string
}

variable "copilot_name" {
  type = string
}

variable "keypair" {
  type = string
}

variable "create_alb" {
  type = bool
}

variable "certificate_arn" {
  type = string
}