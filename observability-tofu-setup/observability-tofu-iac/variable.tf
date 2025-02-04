
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
  default     = "arn:aws:acm:eu-west-2:533267093295:certificate/4e3ea00d-b260-4dde-9c99-bc4095280892"
}

variable "domain_name" {
  type        = string
  description = "Domain name for Route53"
  default     = "example.com"
}

#variable "observability_subdomain" {
#  type        = string
#  description = "Subdomain for observability"
#  default     = "observability"
#}

variable "observability_subdomain" {
  type        = string
  description = "Subdomain for observability"
  default     = "observe"
}

variable "sentry_subdomain" {
  type        = string
  description = "Subdomain for observability"
  default     = "sentry"
}

variable "instance_type" {
  description = "Map of instance types for different roles"
  type = map(string)
  default = {
    bastion = "t2.micro"
    web     = "m5.4xlarge"
  }
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

