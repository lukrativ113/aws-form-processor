terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.46.0"
    }
    
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
  }
  
  required_version = "1.1.8"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  name_prefix = "${var.prefix}-${var.environ}"
}
