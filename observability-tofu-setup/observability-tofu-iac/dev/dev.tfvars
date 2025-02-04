
environment            = "dev"
aws_region             = "eu-west-2"
vpc_cidr_block         = "172.16.0.0/16"
public_subnets_cidr    = ["172.16.1.0/24", "172.16.2.0/24"]
private_subnets_cidr   = ["172.16.3.0/24", "172.16.4.0/24"]
alb_certificate_arn    = "arn:aws:acm:eu-west-2:533267093295:certificate/4e3ea00d-b260-4dde-9c99-bc4095280892"
domain_name            = "sabitmubarik.com"
#jenkins_subdomain     = "jenkins"
observability_subdomain      = "observe"
sentry_subdomain       = "sentry"
#ami_id                = "ami-00eaa9e98b0de9d0a"
ami_id                 = "ami-084725666251e790b"
bastion_ami_id         = "ami-084725666251e790b"
allowed_ssh_cidr       = "0.0.0.0/0"
key_pair_name          = ""