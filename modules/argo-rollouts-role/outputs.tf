output "argo_rollouts_role_name" {
     description = "ClusterRole name created for Argo Rollouts"
  value = kubernetes_cluster_role.argo_rollouts.metadata[0].name
}
