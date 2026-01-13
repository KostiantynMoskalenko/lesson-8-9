output "argocd_namespace" {
  description = "Namespace with ArgoCD"
  value       = kubernetes_namespace.argo.metadata[0].name
}
