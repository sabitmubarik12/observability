
output "ec2_id" {
  value = aws_instance.observability_ec2.id
}

output "observability_sg_id" {
  value = aws_security_group.observability_sg.id
}

output "ssh_key_pair_public_key" {
  value       = tls_private_key.observability_key[*].public_key_openssh
  description = "Public key if a new one was created"
}

output "ssh_key_pair_private_key" {
  value       = tls_private_key.observability_key[*].private_key_pem
  sensitive   = true
  description = "Private key if a new one was created"
}

