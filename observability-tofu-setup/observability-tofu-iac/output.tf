
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "observability_ec2_id" {
  description = "EC2 observability instance ID"
  value       = module.ec2_observability.ec2_id
}

output "bastion_ec2_id" {
  description = "Bastion instance ID"
  value       = module.bastion.bastion_id
}

output "ssh_key_pair_public_key" {
  description = "Public key content if created"
  value       = module.ec2_observability.ssh_key_pair_public_key
}

output "ssh_key_pair_private_key" {
  description = "Private key content if created"
  sensitive   = true
  value       = module.ec2_observability.ssh_key_pair_private_key
}

output "bastion_ssh_key_pair_public_key" {
  description = "Public key content if created"
  value       = module.bastion.ssh_key_pair_public_key
}

output "bastion_ssh_key_pair_private_key" {
  description = "Private key content if created"
  sensitive   = true
  value       = module.bastion.ssh_key_pair_private_key
}

output "observability_route" {
  description = "Route to access observability"
  value       = "https://${module.route53.observability_fqdn}"
}

