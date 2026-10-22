## Permissions for creating token
- Fine Grained Token
  - Repositories
    - tgb-shopverse-gitops (Select more than one if you need)
  - Permissions
    - Administration : Read and write
    - Metadata: Read
  
## Create Secret
```bash
kubectl create secret generic shopverse-gitops-gha-arc-token \
  -n arc-runners \
  --from-literal=github_token='YOUR_GITHUB_TOKEN'
```
