 variable "aws_vpc_id" {
   description = "value of aws vpc id"
   type = string
 }

variable "ssh_key" {
  description = "The SSH key name to access the GitHub Actions runner EC2 instance"
  type        = string
  default = "virg.keypair"
}

variable "github_runner_token" {
  default = "AWPCBFYNM2V7AG4FE3XITPDJDSTEM"
  description = "github token"
}


variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "cluster name"
  default = "multi-cloud-cluster"
} 

variable "aws_public_subnet_ids" {
  description = "CIDR blocks for AWS public subnets"
  type = list(string)
}

     

