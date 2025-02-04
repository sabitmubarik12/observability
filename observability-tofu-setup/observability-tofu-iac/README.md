1 Create a hosted zone already.
2 Create acm and paste where applicable in code.
3 Update the region.
4 Update the domain name.
5 Update the ami with the one created from either packer or any base ami.
# observability + ALB + Bastion with OpenTofu

This Terraform/OpenTofu configuration deploys:
- A VPC with public and private subnets.
- An ALB (Application Load Balancer) with HTTP->HTTPS redirection.
- A observability EC2 instance in private subnets, accessible only via the ALB on port 80.
- A Bastion host in a public subnet (for SSH into observability).
- Route53 DNS record for observability subdomain.
- Optional auto-created SSH key pairs if none are provided.

## Usage

1. **Initialize**: `tofu init -backend-config=dev/backend.hcl`
2. **Plan**: `tofu plan -var-file=dev/dev.tfvars`
3. **Apply**: `tofu apply -var-file=dev/dev.tfvars`
4. **GetPrivateKey**: `tofu output -json ssh_key_pair_private_key`
5. **GetBastionPrivateKey**: `tofu output -json bastion_ssh_key_pair_private_key`
6. **Destroy**: `tofu destroy -var-file=dev/dev.tfvars`