# Full Project Execution Flow
## 1. Create the required infrastructure  
```bash
terraform apply s3

terraform apply -target=module.vpc
terraform apply -target=module.bastion_ec2
terraform apply -target=module.nat_instance
terraform apply -target=module.ecr
terraform apply -target=module.eks
terraform apply -target=module.secrets_manager
terraform apply -target=module.rds
terraform apply -target=module.alb

terraform apply argocd
terraform apply eso
terraform apply aws-lbc
```
## 2. If u want ARC Runner for CI
```bash
terraform apply 91-ARC
```

## 3. Create ESO secrets in Kubernetes
repo: `tgb-shopverse-gitops`
```bash
cd k8s/eso-external-secrets

kubectl apply -f cluster-secret-store.yaml
kubectl apply -f dev-external-secrets.yaml
```

## 4. If u want ARC Runner 
- **for CI**  
repo: `tgb-shopverse-gitops`  
```bash
cd k8s/rbac/platform

kubectl apply -f gha-arc-runner-sa.yaml
```
- **for GITOPS**                         
repo: `tgb-shopverse-gitops`  
```bash
cd k8s/rbac/platform

kubectl apply -f gitops-arc-runner-sa-perms.yaml
```

## 5. Create ARC Runner ArgoCD applications    
repo: `tgb-shopverse-gitops`  

- **Create Secret**  
```bash
# Create secret
# Fine grained Token: tgb-shopverse-infra, backend, frontend, gitops (Admin: read and write)

kubectl create secret generic shopverse-gha-arc-token \
  -n arc-runners \
  --from-literal=github_token=<GITHUB_TOKEN>
```
- **Create Projects**  
```bash
cd argocd/platform/gha-arc-runners/projects

kubectl apply -f 01-arc-controller.yaml
kubectl apply -f 02-arc-runners.yaml
```
- **Create Applications**  
```bash
cd argocd/platform/gha-arc-runners/apps

kubectl apply -f 01-controller.yaml
kubectl apply -f 02-infra-arc-runner.yaml
kubectl apply -f 03-frontend-arc-runner.yaml
kubectl apply -f 04-backend-arc-runner.yaml
kubectl apply -f 05-gitops-arc-runner.yaml
```

## 6. Create Project related ArgoCD Applications  
repo: `tgb-shopverse-gitops`  

- **Create Project**  
```bash
cd argocd/dev/projects
kubectl apply -f shopverse-dev.yaml
```
- **Create ApplicationSet**  
```bash
cd atgocd/dev/apps
kubectl apply -f applicationset.yaml
```





