
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

