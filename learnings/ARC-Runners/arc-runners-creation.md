# -----------------------   ARC Runners Creation   -----------------------
## 1. Repository layout  
In `vaheed-valaxy/shopverse-gitops`, create a dedicated ARC directory:  
```text
shopverse-gitops/
├── argocd/
│   └── applications/
│       ├── arc-controller.yaml
│       └── arc-runners.yaml
└── helm-charts-new/
    └── platform/
        └── arc/
            ├── controller/
            │   └── values.yaml
            └── runners/
                └── values.yaml
```

GitHub recommends installing the controller and runner scale sets in separate namespaces.  
The two installations will be:  
- `arc-controller` in `arc-systems` namespace  
- `shopverse-dev-runners` in `arc-runners` namespace  
The runner scale set name is what you'll reference in your workflow's `runs-on`.

## 2. Install the ARC controller through Argo CD  
Create `argocd/applications/arc-controller.yaml`:  
```yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: arc-controller
  namespace: argocd
spec:
  project: shopverse-dev-app-project

  source:
    repoURL: ghcr.io/actions/actions-runner-controller-charts
    chart: gha-runner-scale-set-controller
    targetRevision: "0.15.0"    # "0.13.0"
    helm:
      releaseName: arc-controller
      values: |
        replicaCount: 1

  destination:
    server: https://kubernetes.default.svc
    namespace: arc-systems

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```












