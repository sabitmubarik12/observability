
variable "environment" {
  type = string
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

variable "bastion_sg_id" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}

