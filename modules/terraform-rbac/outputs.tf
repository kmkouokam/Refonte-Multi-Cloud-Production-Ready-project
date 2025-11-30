# Output the IAM role ARN
output "terraform_iam_role_arn" {
  value = aws_iam_role.terraform.arn
}
