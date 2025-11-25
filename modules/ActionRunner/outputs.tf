output "runner_role_arn" {
  description = "The ARN of the IAM role for the GitHub Actions runner."
  value       = aws_iam_role.github_runner_role.arn
}
  
