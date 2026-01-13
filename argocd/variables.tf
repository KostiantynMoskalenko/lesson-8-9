variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "kosmos"
}

variable "aws_region" {
  description = "AWS region for AWS provider (має відповідати регіону EKS)"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cluster1"
}

variable "eks_state_key" {
  description = "S3 key for remote state EKS"
  type        = string
  default     = "eks/terraform.tfstate"
}

variable "eks_state_region" {
  description = "Backet region with remote state EKS"
  type        = string
  default     = "us-east-1"
}

variable "argocd_namespace" {
  description = "Namespace для ArgoCD"
  type        = string
  default     = "infra-tools"
}

variable "argocd_chart_version" {
  description = "Helm-chart version ArgoCD"
  type        = string
  default     = "7.7.5"
}

variable "app_repo_url" {
  description = "Publicй Git-repository with manifests"
  type        = string
  default     = "https://github.com/KostiantynMoskalenko/lesson-8-9.git"
}

variable "app_repo_branch" {
  description = "Git branch"
  type        = string
  default     = "main"
}