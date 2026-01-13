# MLflow Experiments Tracking with ArgoCD, PostgreSQL and Prometheus PushGateway

This project demonstrates ML experiment tracking with MLflow, automatic model selection, and exporting experiment metrics via Prometheus PushGateway, deployed declaratively using ArgoCD.

## Preconditions
The clustr created on previos steps. See https://github.com/KostiantynMoskalenko/lesson-5-6
ArgoCD will watch to lesson-5-6/mlops-experiments/argocd/applications
Deployment and configuration files placed in https://github.com/KostiantynMoskalenko/lesson-8-9/argocd

## MLflow Deployment with ArgoCD on EKS:
```
cd argocd
```

## Terrafrm initialization for ArgoCD:
```
   terraform init
   terraform plan
   terraform apply
```

## Pods checkinf:

```
kubectl get pods -n infra-tools
```

## Add necessary changes in "main.tf" file
Start from "# Bootstrap GitOps repo (ArgoCD will watch in /applications)....." and below in "main.tf" file.


## Update and deploy terrafom:

```
terraform init -reconfigure  
terraform plan
terraform apply
```

## Check applications for every folder:

```
kubectl get applications -n infra-tools
```

## Access getting for ArgoCD UI:
1. Get password:
   ```
   $encodedPassword = kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
   [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPassword))
   ```
2. Port forwarding:
   ```   
   kubectl port-forward svc/argocd-server -n infra-tools 8080:80
   ```
3. Open `http://localhost:8080` link in browser, log in with `admin` and the password from the step 1.


## Access getting for MlFlow UI:

1. Port Forwarding:
```
kubectl -n mlflow port-forward svc/mlflow 5000:5000
```

2. Open http://localhost:5000/ link in browser.


There are screenshots with application stages in Argo UI console (localhost:8080) and MlFlow console (localhost:5000):
https://github.com/KostiantynMoskalenko/lesson-8-9/screens/


Run Experiments (local execution)

Prepare Python environment:
```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
Run training and metric push:
```
export MLFLOW_TRACKING_URI="http://localhost:5000"
export PUSHGATEWAY_URL="http://localhost:9091"
python train_and_push.py
```

