terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  # The same backend block usage as before (if using S3, etc.)
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
