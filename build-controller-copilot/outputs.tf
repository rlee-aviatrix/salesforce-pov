output "result" {
  value = module.aviatrix-controller-initialize.result
}

output "controller_private_ip" {
  value = module.aviatrix-controller-build.private_ip
}

output "controller_public_ip" {
  value = module.aviatrix-controller-build.public_ip
}

output "copilot_private_ip" {
  value = module.copilot_build_aws.private_ip
}

output "copilot_public_ip" {
  value = module.copilot_build_aws.public_ip
}