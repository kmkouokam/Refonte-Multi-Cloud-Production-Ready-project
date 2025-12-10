 

 output "argo_rollouts_role_name" {
  description = "ClusterRole name created for Argo Rollouts"

  value = length(kubernetes_cluster_role.argo_rollouts) > 0 ? kubernetes_cluster_role.argo_rollouts[0].metadata[0].name :null
}

    





