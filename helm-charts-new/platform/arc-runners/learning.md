## 1. Permissions for creating github token (Repository Level)
- **Fine Grained Token**
  - **Repositories**
    - `tgb-shopverse-gitops` (Select more than one repo if you need this token for)
  - **Permissions**
    - `Administration` : ***Read and write***
    - `Metadata`: ***Read***
  
## 2. Create Secret
```bash
kubectl create secret generic shopverse-gitops-gha-arc-token \
  -n arc-runners \
  --from-literal=github_token='YOUR_GITHUB_TOKEN'
```
