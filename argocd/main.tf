# Namespace for ArgoCD
resource "kubernetes_namespace" "argo" {
  metadata {
    name = var.argocd_namespace
  }
}



# ArgoCD installing with Helm-chart
resource "helm_release" "argo" {
  name      = "argocd"
  namespace = kubernetes_namespace.argo.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  recreate_pods = true
  replace       = true
  set {
  name  = "crds.install"
  value = "false"
}

  values = [file("${path.module}/values/argocd-values.yaml")]
  depends_on = [kubernetes_namespace.argo]
}



# Bootstrap GitOps repo (ArgoCD will watch in /applications)
resource "kubernetes_manifest" "argocd_gitops_repo" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "gitops-root"
      namespace = kubernetes_namespace.argo.metadata[0].name
    }
    spec = {
      project = "default"

    source = {
      repoURL        = "https://github.com/KostiantynMoskalenko/lesson-8-9"
      targetRevision = "main"
      path           = "mlops-experiments/argocd/applications"
    }

    destination = {
      server    = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace.argo.metadata[0].name  # infra-tools
    }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argo]
}


