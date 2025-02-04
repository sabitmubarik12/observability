
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

