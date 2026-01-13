terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-kmos"
    key     = "argocd/terraform.tfstate"
    region  = "us-east-1"
    profile = "kosmos"
  }
}
