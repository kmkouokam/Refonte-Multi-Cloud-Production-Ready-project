output "alb_controller_irsa_role_arn" {
  value       = aws_iam_role.alb_controller.arn
  description = "IRSA role ARN for AWS Load Balancer Controller"
}
