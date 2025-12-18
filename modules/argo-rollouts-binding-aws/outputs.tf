# Output the IAM role ARN
output "terraform_iam_role_arn" {
  value = aws_iam_role.terraform[0].arn
} 

# === modules/argo-rollouts-binding-aws/outputs.tf ===
output "github_runner_service_account_name" {
value = kubernetes_service_account.github_runner[0].metadata[0].name
description = "ServiceAccount created for the GitHub runner"
}


# output "argo_rollouts_binding_name" {
# value = kubernetes_cluster_role_binding.argo_rollouts_runner_binding[0].metadata[0].name
# }
