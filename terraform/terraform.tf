terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "dev"
}
