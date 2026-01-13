# ArgoCD + MLflow GitOps Deployment

## Загальна послідовність виконнаня роботи

1. Через Terraform розгортається ArgoCD в існуючому EKS-кластері
2. Створюється окремий Git-репозиторій goit-argo для GitOps
3. Через Git створюються namespace application та infra-tools
4. Деплоїться тестовий застосунок nginx для перевірки GitOps
5. Після цього створюється Application для MLflow
6. Кластер автоматично підтягує зміни з Git


## 0. Структура Terraform для ArgoCD
Структура terraform:
```
terraform/
└──	argocd/
		├── main.tf
		├── variables.tf
		├── provider.tf
		├── outputs.tf
		├── terraform.tf
		├── backend.tf
		└── values/
		    └── argocd-values.yaml
```


## 1. Ініціалізація Terraform для ArgoCD
```
cd terraform/argocd
terraform init -reconfigure
terraform plan
```



## 2. Деплой ArgoCD через Terraform
```
terraform apply
```



## 3. Перевірка pod-ів ArgoCD
```
kubectl get pods -n infra-tools
```



## 4. Отримання паролю для входу в UI ArgoCD
```
kubectl -n infra-tools get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```



## 5. Відкриття ArgoCD UI через port-forward
```
kubectl port-forward svc/argocd-server -n infra-tools 8080:80
```
Після цього UI доступний за адресою: http://localhost:8080


## 6. Створення файлів для майбутньої Git (GitOps) інфраструктури
Структура репозиторію goit-argo:
```
namespaces/
├── application/
│   ├── ns.yaml
│   └── nginx.yaml
└── infra-tools/
    └── ns.yaml
```
Пушимо зміни у віддалений репозиторій:
```
git add .
git commit -m "Add namespaces structure for GitOps"
git push
```


## 7. Готуємо Terraform під Argo CD, щоб він дивився на namespace
### Додали додаткову конфігурацію
 - у файл variables.tf: app_repo_url та app_repo_branch
 - у файл main.tf: прописали сканувати репозиторії у "namespaces/*"

### Підтягнули зміни до кластера 
```
terraform init -reconfigure  
terraform apply
```

### Оновлення стану ApplicationSet
```
kubectl -n infra-tools annotate applicationset namespaces-appset \
argocd.argoproj.io/application-set-refresh=force --overwrite
```


## 8. Перевірка Applications від ApplicationSet
```
kubectl get applications -n infra-tools
```


## 9. Додавання ArgoCD Application для MLflow у Git
Створюємо і додаємо файл на віддалений репозиторій для постійних оновлень:
```
git add application.yaml
git commit -m "Add MLflow ArgoCD Application"
git push
```


## 10. Перевірка стану додатка
У UI інтерфейсі. 

## 11. Перевірка pod-ів MLflow
```
kubectl get pods -n application
```


## 12. Перекидання MLflow через port-forward для доступу через UI
```
kubectl port-forward svc/mlflow -n application 5000:5000
```


## 13. Перегляд Applications у UI ArgoCD
У UI інтерфейсі. 
