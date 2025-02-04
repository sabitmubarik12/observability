#!/usr/bin/env bash

################################################################################
# Script to create an OpenTofu-based project for observability + ALB + Bastion setup #
################################################################################

# Base directory name
BASE_DIR="observability-tofu-iac"

# 1. Define directory structure
DIRECTORIES=(
  "$BASE_DIR/dev"
  "$BASE_DIR/modules/alb"
  "$BASE_DIR/modules/ec2"
  "$BASE_DIR/modules/network"
  "$BASE_DIR/modules/route53"
  "$BASE_DIR/modules/bastion"
)

# 2. Define files and their content
#    Each file path -> multiline content string
declare -A FILES_CONTENT

FILES_CONTENT["$BASE_DIR/README.md"]='
# observability + ALB + Bastion with OpenTofu

This Terraform/OpenTofu configuration deploys:
- A VPC with public and private subnets.
- An ALB (Application Load Balancer) with HTTP->HTTPS redirection.
- A observability EC2 instance in private subnets, accessible only via the ALB on port 8080.
- A Bastion host in a public subnet (for SSH into observability).
- Route53 DNS record for observability subdomain.
- Optional auto-created SSH key pairs if none are provided.

## Usage

1. **Initialize**: `opentofu init -backend-config=dev/backend.hcl`
2. **Plan**: `opentofu plan -var-file=dev/dev.tfvars`
3. **Apply**: `opentofu apply -var-file=dev/dev.tfvars`
'

FILES_CONTENT["$BASE_DIR/provider.tf"]='
terraform {
  required_version = ">= 1.0.0"

  # The backend config is loaded from dev/backend.hcl
  backend "s3" {}

  required_providers {
    # In real usage, you might have "hashicorp/aws" or a different provider.
    # Here, we assume a hypothetical "opentofu" provider plugin for demonstration.
    opentofu = {
      source  = "local/opentofu"
      version = ">= 1.0"
    }
  }
}

provider "opentofu" {
  region = var.aws_region
}
'

FILES_CONTENT["$BASE_DIR/variable.tf"]='
variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-2"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "List of public subnet CIDRs"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "List of private subnet CIDRs"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "alb_certificate_arn" {
  type        = string
  description = "ARN of ACM certificate"
  default     = "arn:aws:acm:eu-west-2:533267093295:certificate/264f18f2-1e0e-4e9a-a1ba-67f579e987ef"
}

variable "domain_name" {
  type        = string
  description = "Domain name for Route53"
  default     = "example.com"
}

variable "observability_subdomain" {
  type        = string
  description = "Subdomain for observability"
  default     = "observability"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ami_id" {
  type        = string
  description = "AMI for observability EC2"
  default     = "ami-05c172c7f0d3aed00"
}

variable "bastion_ami_id" {
  type        = string
  description = "AMI for Bastion EC2"
  default     = "ami-05c172c7f0d3aed00"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH into Bastion"
  default     = "0.0.0.0/0"
}

variable "key_pair_name" {
  type        = string
  description = "Optional existing key pair name"
  default     = ""
}
'

FILES_CONTENT["$BASE_DIR/data.tf"]='
# Example if you want to look up an existing certificate or route53 zone
data "aws_acm_certificate" "alb_cert" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
  types    = ["AMAZON_ISSUED"]
}

data "aws_route53_zone" "main_zone" {
  name         = var.domain_name
  private_zone = false
}
'

FILES_CONTENT["$BASE_DIR/dev/backend.hcl"]='
bucket         = "my-terraform-state-bucket"
key            = "states/dev/terraform.tfstate"
region         = "eu-west-2"
dynamodb_table = "my-terraform-locks"
'

FILES_CONTENT["$BASE_DIR/dev/dev.tfvars"]='
environment            = "dev"
aws_region             = "eu-west-2"
vpc_cidr_block         = "10.0.0.0/16"
public_subnets_cidr    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets_cidr   = ["10.0.3.0/24", "10.0.4.0/24"]
alb_certificate_arn    = "arn:aws:acm:eu-west-2:533267093295:certificate/264f18f2-1e0e-4e9a-a1ba-67f579e987ef"
domain_name            = "sabitmubarik.com"
observability_subdomain      = "observability"
instance_type          = "t3.micro"
ami_id                 = "ami-05c172c7f0d3aed00"
bastion_ami_id         = "ami-05c172c7f0d3aed00"
allowed_ssh_cidr       = "0.0.0.0/0"
key_pair_name          = ""
'

FILES_CONTENT["$BASE_DIR/main.tf"]='
module "network" {
  source                = "./modules/network"
  environment           = var.environment
  vpc_cidr_block        = var.vpc_cidr_block
  public_subnets_cidr   = var.public_subnets_cidr
  private_subnets_cidr  = var.private_subnets_cidr
}

module "alb" {
  source              = "./modules/alb"
  environment         = var.environment
  vpc_id              = module.network.vpc_id
  public_subnets      = module.network.public_subnets
  alb_certificate_arn = var.alb_certificate_arn
  observability_target_port = 8080
}

module "ec2_observability" {
  source              = "./modules/ec2"
  environment         = var.environment
  instance_type       = var.instance_type
  ami_id              = var.ami_id
  private_subnets     = module.network.private_subnets
  vpc_id              = module.network.vpc_id
  alb_sg_id           = module.alb.alb_sg_id
  key_pair_name       = var.key_pair_name
}

module "bastion" {
  source            = "./modules/bastion"
  environment       = var.environment
  instance_type     = var.instance_type
  ami_id            = var.bastion_ami_id
  public_subnets    = module.network.public_subnets
  vpc_id            = module.network.vpc_id
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  key_pair_name     = var.key_pair_name
  observability_sg_id     = module.ec2_observability.observability_sg_id
}

module "route53" {
  source             = "./modules/route53"
  environment        = var.environment
  domain_name        = var.domain_name
  observability_subdomain  = var.observability_subdomain
  alb_dns_name       = module.alb.alb_dns_name
  hosted_zone_id     = data.aws_route53_zone.main_zone.zone_id
}
'

FILES_CONTENT["$BASE_DIR/output.tf"]='
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

output "observability_route" {
  description = "Route to access observability"
  value       = "https://${module.route53.observability_fqdn}"
}
'

# -------------------
# Module: network
# -------------------
FILES_CONTENT["$BASE_DIR/modules/network/variables.tf"]='
variable "environment" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "public_subnets_cidr" {
  type = list(string)
}

variable "private_subnets_cidr" {
  type = list(string)
}
'

FILES_CONTENT["$BASE_DIR/modules/network/main.tf"]='
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_eip" "ngw_eip" {
  vpc = true
  # We let it depend on IGW just to ensure ordering
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.environment}-ngw-eip"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.environment}-nat-gateway"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidr[count.index]
  map_public_ip_on_launch = true

  # For demonstration, you might pin subnets to different AZs if available
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${var.environment}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count      = length(var.private_subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets_cidr[count.index]

  availability_zone = "eu-west-2b"

  tags = {
    Name = "${var.environment}-private-subnet-${count.index}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
'

FILES_CONTENT["$BASE_DIR/modules/network/outputs.tf"]='
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnets" {
  value = [for s in aws_subnet.private : s.id]
}
'

# -------------------
# Module: alb
# -------------------
FILES_CONTENT["$BASE_DIR/modules/alb/variables.tf"]='
variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "alb_certificate_arn" {
  type = string
}

variable "observability_target_port" {
  type    = number
  default = 8080
}
'

FILES_CONTENT["$BASE_DIR/modules/alb/main.tf"]='
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description   = "Allow HTTP from anywhere"
    from_port     = 8080
    to_port       = 8080
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  ingress {
    description   = "Allow HTTPS from anywhere"
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_lb" "observability_alb" {
  name               = "${var.environment}-observability-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${var.environment}-observability-alb"
  }
}

resource "aws_lb_target_group" "observability_tg" {
  name     = "${var.environment}-observability-tg"
  port     = var.observability_target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = "traffic-port"
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "${var.environment}-observability-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.observability_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "302"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.observability_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.observability_tg.arn
  }
}
'

FILES_CONTENT["$BASE_DIR/modules/alb/outputs.tf"]='
output "alb_arn" {
  value = aws_lb.observability_alb.arn
}

output "alb_dns_name" {
  value = aws_lb.observability_alb.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "observability_tg_arn" {
  value = aws_lb_target_group.observability_tg.arn
}
'

# -------------------
# Module: ec2 (observability)
# -------------------
FILES_CONTENT["$BASE_DIR/modules/ec2/variables.tf"]='
variable "environment" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}
'

FILES_CONTENT["$BASE_DIR/modules/ec2/main.tf"]='
resource "aws_security_group" "observability_sg" {
  name        = "${var.environment}-observability-sg"
  description = "Security group for observability EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-observability-sg"
  }
}

# If no key_pair_name is supplied, create a new key pair
resource "tls_private_key" "observability_key" {
  count = var.key_pair_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "observability_keypair" {
  count     = var.key_pair_name == "" ? 1 : 0
  key_name  = "${var.environment}-observability-key"
  public_key = tls_private_key.observability_key[0].public_key_openssh
}

resource "aws_instance" "observability_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = element(var.private_subnets, 0)  # put in first private subnet
  vpc_security_group_ids = [aws_security_group.observability_sg.id]

  key_name = var.key_pair_name == "" ? aws_key_pair.observability_keypair[0].key_name : var.key_pair_name

  tags = {
    Name = "${var.environment}-observability-instance"
  }

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    # Install observability or other required software...
    # Example:
    amazon-linux-extras install epel -y
    yum install java-11-amazon-corretto -y
    echo "observability installed" > /tmp/observability_install.txt
  EOT
}
'

FILES_CONTENT["$BASE_DIR/modules/ec2/outputs.tf"]='
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
'

# -------------------
# Module: bastion
# -------------------
FILES_CONTENT["$BASE_DIR/modules/bastion/variables.tf"]='
variable "environment" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "observability_sg_id" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}
'

FILES_CONTENT["$BASE_DIR/modules/bastion/main.tf"]='
resource "aws_security_group" "bastion_sg" {
  name        = "${var.environment}-bastion-sg"
  description = "Security Group for Bastion"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Egress to allow SSH to observability EC2
  egress {
    description     = "Allow SSH to observability"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.observability_sg_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-bastion-sg"
  }
}

resource "tls_private_key" "bastion_key" {
  count = var.key_pair_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "bastion_keypair" {
  count      = var.key_pair_name == "" ? 1 : 0
  key_name   = "${var.environment}-bastion-key"
  public_key = tls_private_key.bastion_key[0].public_key_openssh
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(var.public_subnets, 0)
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  key_name = var.key_pair_name == "" ? aws_key_pair.bastion_keypair[0].key_name : var.key_pair_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.environment}-bastion"
  }
}
'

FILES_CONTENT["$BASE_DIR/modules/bastion/outputs.tf"]='
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
'

# -------------------
# Module: route53
# -------------------
FILES_CONTENT["$BASE_DIR/modules/route53/variables.tf"]='
variable "environment" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "observability_subdomain" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}
'

FILES_CONTENT["$BASE_DIR/modules/route53/main.tf"]='
resource "aws_route53_record" "observability_record" {
  zone_id = var.hosted_zone_id
  name    = "${var.observability_subdomain}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}
'

FILES_CONTENT["$BASE_DIR/modules/route53/outputs.tf"]='
output "observability_fqdn" {
  value = "${var.observability_subdomain}.${var.domain_name}"
}
'

################################################################################
# Create directories
################################################################################
for dir in "${DIRECTORIES[@]}"; do
  mkdir -p "$dir"
done

################################################################################
# Create files with their contents
################################################################################
for file_path in "${!FILES_CONTENT[@]}"; do
  # Use 'echo -e' to handle any escaped characters in the content
  echo "${FILES_CONTENT[$file_path]}" > "$file_path"
done

echo "OpenTofu project structure created in '$BASE_DIR' successfully!"

################################################################################
# Next steps (informational message)
################################################################################
echo -e "\nTo use this infrastructure:"
echo "1. cd $BASE_DIR"
echo "2. tofu init -backend-config=dev/backend.hcl"
echo "3. tofu plan -var-file=dev/dev.tfvars"
echo "4. tofu apply -var-file=dev/dev.tfvars"
echo -e "\nHappy Tofu-ing!"