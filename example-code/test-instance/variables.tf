variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "private_ip" {
  type    = string
  default = null
}

variable "instance_type" {
  type = string
}

variable "user_data" {
  type    = string
  default = null
}