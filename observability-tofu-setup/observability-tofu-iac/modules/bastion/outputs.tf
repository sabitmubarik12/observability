
output "bastion_id" {
  value = aws_instance.bastion.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "ssh_key_pair_public_key" {
  value = tls_private_key.bastion_key[*].public_key_openssh
}

output "ssh_key_pair_private_key" {
  value     = tls_private_key.bastion_key[*].private_key_pem
  sensitive = true
}

