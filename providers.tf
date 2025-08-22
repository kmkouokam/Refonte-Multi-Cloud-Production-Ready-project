terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}



provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("${path.module}/${var.gcp_credentials_file}") # Optional if using ADC
}

provider "aws" {
  region = var.aws_region
}

provider "random" {
  # No configuration required
}
