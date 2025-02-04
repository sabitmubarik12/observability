
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

