
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
  default = 80
}

# variable "observability_instance_ids" {
#   type = list(string)
# }

variable "observability_instance_ids" {
  type        = list(string)
  description = "List of observability EC2 instance IDs"
  default     = [] 
}