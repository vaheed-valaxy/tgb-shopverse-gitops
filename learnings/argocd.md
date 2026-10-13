## Get ArgoCD initial admin secret
```text
argocd user: admin
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode && echo
```

## ArgoCD port forward
```bash
kubectl port-forward -n argocd svc/argocd-server 8090:443 --address 0.0.0.0
```

## Install ArgoCD CLI
```bash
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)

curl -sSL \
  -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/download/v${VERSION}/argocd-linux-amd64

sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

rm -f argocd-linux-amd64

argocd version --client
```

## Login to ArgoCD
```bash
argocd login 127.0.0.1:8090 --username admin --password ZjVNPFGA3cAJIcXC --insecure
argocd account get-user-info
```

## Get ArgoCD Project
```bash
argocd proj get shopverse-dev
kubectl -n argocd get appproject shopverse-dev -o yaml

argocd proj role list shopverse-dev
argocd proj role get shopverse-dev github-actions-dev
```

## Create ArgoCD token 
```bash
argocd proj role create-token <project-name> <role-name> --expires-in 30d

argocd proj role create-token \
  shopverse-dev \
  shopverse-gh-actions-dev  \
  --expires-in 30d
```

## List the ArgoCD Apps
```bash
argocd app list
argocd app get <YOUR-DEV-APP>
argocd app sync <YOUR-DEV-APP>
```

