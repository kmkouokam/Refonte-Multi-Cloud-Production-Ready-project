variable "aws_region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "availability_zone" {
  description = "The availability zone to deploy resources in"
  type        = string
  default     = "us-east-1a"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "cloud_provider" {
  description = "The cloud provider to use (aws or gcp)"
  type        = string
  default     = "aws"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "multi-cloud-vpc"
}

variable "public_subnet_cidrs" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "aws_kms_alias" {
  description = "KMS key alias for encryption"
  type        = string
  default     = "alias/refonte-multicloud-kms-key"
}




