
module "network" {
  source               = "./modules/network"
  environment          = var.environment
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
}

module "alb" {
  source                     = "./modules/alb"
  environment                = var.environment
  vpc_id                     = module.network.vpc_id
  public_subnets             = module.network.public_subnets
  observability_instance_ids = [module.ec2_observability.ec2_id]
  alb_certificate_arn        = var.alb_certificate_arn
  observability_target_port  = 80
}

module "ec2_observability" {
  source          = "./modules/ec2"
  environment     = var.environment
#  instance_type   = var.instance_type["web"]
  instance_type  = var.instance_type
  ami_id          = var.ami_id
  private_subnets = module.network.private_subnets
  vpc_id          = module.network.vpc_id
  alb_sg_id       = module.alb.alb_sg_id
  bastion_sg_id   = module.bastion.bastion_sg_id
  key_pair_name   = var.key_pair_name
}

module "bastion" {
  source              = "./modules/bastion"
  environment         = var.environment
#  instance_type  = var.instance_type["bastion"]
  instance_type  = var.instance_type
  ami_id              = var.bastion_ami_id
  public_subnets      = module.network.public_subnets
  vpc_id              = module.network.vpc_id
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  key_pair_name       = var.key_pair_name
  observability_sg_id = module.ec2_observability.observability_sg_id
}

module "route53" {
  source                  = "./modules/route53"
  environment             = var.environment
  domain_name             = var.domain_name
  observability_subdomain = var.observability_subdomain
  sentry_subdomain        = var.sentry_subdomain
  alb_dns_name            = module.alb.alb_dns_name
  hosted_zone_id          = data.aws_route53_zone.main_zone.zone_id
}

