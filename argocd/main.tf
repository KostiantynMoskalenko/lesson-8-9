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

#Prometeus
resource "prometheus_manifest" "argocd_prometheus_repo" {
  manifest = {
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus-operator
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: infra-tools
    server: "https://kubernetes.default.svc"
  source:
    repoURL: "https://prometheus-community.github.io/helm-charts"
    targetRevision: 75.16.1
    chart: kube-prometheus-stack
    helm:
      valuesObject:
        nameOverride: "prometheus-operator"
        defaultRules:
          create: true
          rules:
            cpu: true
            memory: true
        prometheus:
          ingress:
            enabled: false
          thanosService:
            enabled: false
          thanosIngress:
            enabled: false
          prometheusSpec:
            serviceMonitorSelector: {}
            serviceMonitorSelectorNilUsesHelmValues: false
            retention: 2d   
        kubelet:
          enabled: true
          serviceMonitor:
            enabled: true
        alertmanager:
          enabled: true
          ingress:
            enabled: false
          alertmanagerSpec:
            forceEnableClusterMode: true
            configSecret: alertmanager-secret
        grafana:
          ingress:
            enabled: false
          adminPassword: prom-operator
        prometheusOperator:
          admissionWebhooks:
            enabled: false
            patch:
              enabled: false
            certManager:
              enabled: false
            autoGenerateCert: false
          tls:
            enabled: false
        kube-state-metrics:
          prometheus:
            monitor:
              enabled: true
        prometheus-node-exporter:
          service:
            port: 9200
  project: default
  syncPolicy:
    syncOptions:
    - Replace=true
    - ServerSideApply=true
    automated:
      prune: true
      selfHeal: true
}
}