 

variable "ssh_key" {
  description = "The SSH key name to access the GitHub Actions runner EC2 instance"
  type        = string
  default = "virg.keypair"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}

     

