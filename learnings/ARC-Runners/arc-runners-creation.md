# ***********************   ARC Runners Creation   ***********************
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

## 3. Install the ARC controller through Argo CD  
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

## 4. Create the runner scale set values  
Create `helm-charts-new/platform/arc/runners/values.yaml`:  
```yaml

githubConfigUrl: "https://github.com/vaheed-valaxy/shopverse-gitops"

githubConfigSecret: shopverse-github-app

runnerScaleSetName: shopverse-dev-runners

minRunners: 0
maxRunners: 3

containerMode:
  type: dind

template:
  spec:
    containers:
      - name: runner
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
```

This configuration:  
- Registers runners specifically for shopverse-gitops.  
- Starts with zero idle runners.  
- Allows ARC to scale up to three concurrent runner jobs.  
- Enables Docker-in-Docker for workflows that build Docker images.  
- Defines initial CPU and memory resources for the runner container.  

GitHub documents the dind container mode for Docker-based workflows. It requires privileged container operation, so isolate these runners from application workloads and do not use this configuration for untrusted pull-request code without additional security controls.  

## 4. Create the runner scale set Argo CD Application
Create `argocd/applications/arc-runners.yaml`:  
```yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: arc-runners
  namespace: argocd
spec:
  project: shopverse-dev-app-project

  sources:
    - repoURL: ghcr.io/actions/actions-runner-controller-charts
      chart: gha-runner-scale-set
      targetRevision: "0.15.0"
      helm:
        releaseName: shopverse-dev-runners
        valueFiles:
          - $values/helm-charts-new/platform/arc/runners/values.yaml

    - repoURL: https://github.com/vaheed-valaxy/shopverse-gitops.git
      targetRevision: main
      ref: values

  destination:
    server: https://kubernetes.default.svc
    namespace: arc-runners

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```
This uses Argo CD's multi-source support: the Helm chart comes from GitHub's OCI registry, and the values file comes from your GitOps repository.  


## 5. Check your AppProject permissions  
Your existing `shopverse-dev-app-project` must allow the GitOps repository, the ARC Helm chart repository, and both target namespaces.  
Check `argocd/projects/shopverse-dev-app-project.yaml` (use your actual file path if different). Its relevant settings should include: 

```yaml
spec:
  sourceRepos:
    - https://github.com/vaheed-valaxy/shopverse-gitops.git
    - ghcr.io/actions/actions-runner-controller-charts

  destinations:
    - namespace: arc-systems
      server: https://kubernetes.default.svc
    - namespace: arc-runners
      server: https://kubernetes.default.svc
```
Merge these entries into your existing project specification rather than replacing its other permissions. If your GitOps repository is private, make sure Argo CD already has repository credentials configured.  

## 6. Deploy in the correct order  
Because the runner scale set depends on the ARC controller and its installed custom resource definitions, deploy the controller first. 

**1.** Commit `arc-controller.yaml` and sync the `arc-controller` Application in Argo CD.
**2.** Verify the controller is healthy:
```bash
kubectl get pods -n arc-systems
kubectl get crds | grep actions.github.com
```
**3.** Commit arc-runners.yaml and helm-charts-new/platform/arc/runners/values.yaml.
**4.** Sync the arc-runners Application.
**5.** Check the resulting resources:
```bash
kubectl get pods -n arc-runners
kubectl get autoscalingrunnersets -n arc-runners
kubectl get ephemeralrunners -n arc-runners
```
The listener pod can remain running even when there are no job-executing runner pods. `With minRunners: 0`, the runner pods should be created on demand.

## 7. Update a GitHub Actions workflow to use ARC  
Once the runner scale set is online, update a test workflow in `shopverse-gitops`:
```yaml
name: Test ARC Runner

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  test:
    runs-on: shopverse-dev-runners

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Verify runner environment
        run: |
          echo "Running on an ephemeral ARC runner"
          uname -a
          docker --version
```
The `runs-on` value must match the configured scale set name.  
Trigger the workflow manually from GitHub's Actions tab.  
While the job is running, you can observe runner pods: 

```bash
kubectl get pods -n arc-runners -w
```

After the job completes, the job-executing runner pod should be removed. The listener pod and ARC controller remain available to manage subsequent jobs.  

## 9. Important considerations for Shopverse
Before switching your existing CI/CD pipelines to ARC, keep these points in mind:  

- **Docker builds**: Docker-in-Docker requires privileged operation. Isolate ARC runner workloads on a dedicated EKS node group where practical.
- **AWS access**: Use GitHub OIDC to assume narrowly scoped IAM roles for ECR pushes and deployments, rather than giving every runner broad AWS permissions.  
- **Capacity**: `maxRunners: 3` limits concurrent runner jobs for this scale set, but it does not provision extra EKS nodes. Ensure your cluster has enough CPU and memory or configure node autoscaling.  
- **Workflow migration**: Keep your existing `shopverse-dev` EC2 runner until ARC successfully builds, scans, signs, and publishes an image. Migrate workflows gradually so you don't lose your bootstrap path.  
- **Logs**: Configure log retention for ARC controllers and runner workloads before using the system for production pipelines.  


### Recommended rollout: 
1. Install ARC controller through Argo CD.  
2. Configure GitHub App authentication and install the runner scale set.  
3. Run a test workflow on shopverse-dev-runners.  
4. Test your actual Docker build and ECR push pipeline.  
5. Move the remaining CI jobs to ARC and retire the EC2 runner only after validation.  








