terraform {
  backend "s3" {
    bucket = "nuytten-tf-remotestate"
    key    = "form-processor-api/{var.environ}/tfstate"
    region = "us-east-1"
  }

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
}

provider "aws" {
  region = "us-east-1"
}

locals {
  name_prefix = "${var.prefix}-${var.environ}"
}