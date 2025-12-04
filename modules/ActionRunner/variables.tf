variable "aws_vpc_id" {
  description = "value of aws vpc id"
  type        = string
}

 

variable "ssh_key" {
  description = "The SSH key name to access the GitHub Actions runner EC2 instance"
  type        = string
  default     = "virg.keypair"
}

variable "github_runner_token" {
  type = string
  description = "github token"
  default = "AWPCBF3DRJXHRCWU2UKTQY3JGGTUA"
}

variable "runner_instance_type" {
  description = "The instance type for the GitHub Actions runner EC2 instance"
  type        = string
  default     = "t3.medium"
}


variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "cluster name"
  default     = "multi-cloud-cluster"
}

variable "aws_public_subnet_ids" {
  description = "CIDR blocks for AWS public subnets"
  type        = list(string)
}

variable "aws_db_password_arn" {
  description = "ARN of the database password secret from Security module"
  type        = string
}

variable "extra_role_arns" {
  description = "List of extra IAM role ARNs to attach to the GitHub Actions runner."
  type        = list(string)
  default     = []
}

variable "eks_node_role_arn" {
  description = "The ARN of the EKS node IAM role."
  type        = string
}


