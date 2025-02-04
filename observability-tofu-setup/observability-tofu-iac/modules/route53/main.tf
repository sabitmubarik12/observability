resource "aws_route53_record" "observability_record" {
  zone_id = var.hosted_zone_id
  name    = "${var.observability_subdomain}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}

resource "aws_route53_record" "sentry_record" {
  zone_id = var.hosted_zone_id
  name    = "${var.sentry_subdomain}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}