
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

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "observability_sg_id" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}

