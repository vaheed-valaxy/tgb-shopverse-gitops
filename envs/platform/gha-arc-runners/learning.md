## 1. Permissions for creating github token (Repository Level)
- **Fine Grained Token**
  - **Repositories :**
    - `tgb-shopverse-infra`
    - `tgb-shopverse-frontend`
    - `tgb-shopverse-backend`
    - `tgb-shopverse-gitops`
  - **Permissions :**
    - `Administration` : ***Read and write***
    - `Metadata`: ***Read***
  
## 2. Create Secret
```bash
kubectl create secret generic shopverse-gha-arc-token \
  -n arc-runners \
  --from-literal=github_token='YOUR_GITHUB_TOKEN'
```
