output "observability_fqdn" {
  value = "${var.observability_subdomain}.${var.domain_name}"
}

output "sentry_fqdn" {
  value = "${var.sentry_subdomain}.${var.domain_name}"
}