terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }

  backend "s3" {
    bucket = "muridi-viti-terraform-bucket"
    key    = "muridi-viti/procore"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

