terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.aws]
    }
    google = {
      source                = "hashicorp/google"
      configuration_aliases = [google.gcp]
    }
  }
}
