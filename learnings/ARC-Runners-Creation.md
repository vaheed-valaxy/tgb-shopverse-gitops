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
The runner scale set name is what you'll reference in your workflow's runs-on.

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

## 3. Create the `GitHub App` or `PAT Token` secret securely for authentication   
Create a GitHub App with repository **Administration: Read and write** permission, install it on **vaheed-valaxy/shopverse-gitops**, and obtain:
- GitHub App ID
- Installation ID
- Downloaded private key
The private key should not be committed to Git.

### 3.1 Create GitHub App
**Which permissions should your Shopverse GitHub App have?**
For the repository-level runner scale set we are configuring for `vaheed-valaxy/shopverse-gitops`,  
use the following settings from GitHub's official ARC authentication guide  

Permission category	Permission	Access  
Repository permissions	Administration	Read and write  
Repository permissions	Metadata	Read-only  
Organization permissions	Self-hosted runners	Read and write  

Why these permissions?
- **Administration — Read and write:** required for ARC to register and manage runners at repository scope.
- **Metadata — Read-only:** allows the app to access basic repository metadata. GitHub requires this permission for repository access.
- **Self-hosted runners — Read and write:** enables runner management at the organization level as specified in GitHub's ARC authentication instructions.

> Do not grant unrelated permissions such as Contents, Actions, Secrets, or Workflows unless another separate integration genuinely requires them.
> ARC's authentication app does not need broad source-code access merely to manage runners.

**Step:1 Open vaheed-valaxy organization settings - Open Developer settings**  
In the left-hand sidebar of the organization settings page:
1. Scroll down to **Developer settings.**
2. Select **GitHub Apps.**
3. Click **New GitHub App.**

**Step 2 — Fill in the basic information**  
**GitHub App name:** `shopverse-arc-runner`
**Homepage URL:** `https://github.com/actions/actions-runner-controller`
**Webhook**: `uncheck`

**Step 3 — Configure Repository permissions**  
Scroll down to the **Permissions section**. Expand **Repository permissions** and configure:  
**Administration:** `Read and write`  
**Metadata:** `Read-only`  
For each permission, open the access dropdown and select the indicated value. Leave every other repository permission set to **No access**.  

**Step 4 — Configure Organization permissions**  
Expand **Organization permissions** and set:  
**Self-hosted runners:** `Read and write`
Leave unrelated organization permissions set to **No access**.  

> These settings follow GitHub's official ARC authentication instructions. Repository Administration write access is specifically needed for
> repository-level runner registration; it is not needed when registering only at organization scope.


**Step 5 — Configure account installation visibility**  
Find **Where can this GitHub App be installed?**  
Select:   
   **- Only on this account**  

Because the app is owned by `vaheed-valaxy`, this keeps the app private to that account or organization instead of allowing other GitHub accounts to install it.

Click **Create GitHub App** at the bottom of the page.

**Step 6 — Generate the private key**  
After creation, GitHub opens the app's settings page.  
**1. Record the App ID**  
**2. Generate a private key** (Scroll to **Private keys**, click **Generate a private key**, and save the downloaded **.pem** file in a secure location.)
 
**Step 7 — Install the app on your organization**   
The app's existence alone does not grant it repository access. You must install it.    
1. In the app settings sidebar, select **Install App**.  
2. Find `vaheed-valaxy` in the account list.  
3. Click **Install**.
4. If GitHub presents repository selection options, choose **Only select repositories**.
5. Select `shopverse-gitops`.
6. Review the permissions and click the confirmation button to complete installation.  

If ARC will also manage runners for `shopverse-backend` or `shopverse-frontend`, decide whether to install the app on those repositories too. Do not grant repository access to projects that do not need this runner service.

If your organization requires approval for app installation or permission changes, an organization owner must approve the request.


**Step 9 — Retrieve the Installation ID**  
After installing the app, open its installation details.  
The installation URL normally follows this pattern:  

```text
https://github.com/organizations/vaheed-valaxy/settings/installations/INSTALLATION_ID
```

For example, if the URL ends in `/settings/installations/12345678`, the installation ID is `12345678`. Use your actual ID, not this example.  
Keep the three required values together in your secret-management system:  

**Value**	**Where to find it**    
App ID	GitHub App's General settings  
Installation ID	App installation details  
Private key	Downloaded .pem file  

These are the values ARC needs for GitHub App authentication.  



## 5. Store the credentials in AWS Secrets Manager  
For your EKS environment, I recommend AWS Secrets Manager as the durable secret store and External Secrets Operator to synchronize the credentials into Kubernetes.  
Create a secret named, for example: `shopverse/dev/arc/github-app`  
Use this JSON structure:
```json
{
  "github_app_id": "YOUR_APP_ID",
  "github_app_installation_id": "YOUR_INSTALLATION_ID",
  "github_app_private_key": "-----BEGIN RSA PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END RSA PRIVATE KEY-----"
}
```
Use the actual PEM content and preserve its newlines correctly. Depending on the PEM format, the header may say `BEGIN RSA PRIVATE KEY` or `BEGIN PRIVATE KEY`; preserve the downloaded key exactly.

For the ARC Helm chart, the resulting Kubernetes Secret should contain these exact key names:
- `github_app_id`
- `github_app_installation_id`
- `github_app_private_key`

### Verify before installing ARC  
**Use this checklist before proceeding:**    
GitHub App setup checklist                       0 of 8

[] GitHub App is owned by vaheed-valaxy  
[] Repository Administration permission is Read and write  
[] Repository Metadata permission is Read-only  
[] Organization Self-hosted runners permission is Read and write  
[] App is installed on shopverse-gitops   
[] App ID and installation ID are recorded  
[] Private key is stored securely outside Git  
[] AWS Secrets Manager secret contains the three required fields   

### What permissions should you add?  
For your GitHub App `shopverse-arc-runner`, add these **repository permissions** if you want to use it for both ARC and GitOps updates.
**Permission --> Access	--> Purpose**  
Administration --> Read and write --> ARC repository-level runner registration, if using repository scope  
Metadata --> Read-only --> GitHub repository metadata  
Contents --> Read and write	--> Clone, modify Helm values, and push commits  
Pull requests --> Read and write --> Create and update promotion PRs  

Keep the **Organization → Self-hosted runners** permission at Read and write if you're registering ARC runners at the organization level. The Administration permission is not required for organization-level runner registration according to GitHub's ARC documentation.

Only grant permissions needed by your actual workflows. For example, if your job only pushes a direct commit and never creates a PR, you may not need Pull requests write access.  

### How would your workflow use it?  
You would store the App ID, installation ID, and private key securely, then generate a short-lived installation access token during the job.  
```yaml
- name: Generate GitHub App token
  id: app-token
  uses: actions/create-github-app-token@v2
  with:
    app-id: ${{ secrets.SHOPVERSE_APP_ID }}
    private-key: ${{ secrets.SHOPVERSE_APP_PRIVATE_KEY }}
    owner: vaheed-valaxy
    repositories: shopverse-gitops

- name: Checkout GitOps repository
  uses: actions/checkout@v4
  with:
    repository: vaheed-valaxy/shopverse-gitops
    token: ${{ steps.app-token.outputs.token }}
    persist-credentials: true
```
The example assumes the App has been installed on the organization and granted access to `shopverse-gitops`. Store the private key and App ID as GitHub Actions secrets, or retrieve them through your existing secrets-management setup.  

You can then update the Helm values file and push a commit using Git. For a PR-based promotion, use the same token with a PR creation action. Installation tokens expire after one hour, so generate one when the job needs it.    


### 3.2 Create PAT Token  
Yes. **You can authenticate ARC using a Personal Access Token (PAT) instead of a GitHub App**. GitHub officially supports classic PATs and fine-grained PATs for ARC.
For your Shopverse EKS setup, you can choose either approach:  

**Feature**	            -->             **PAT**	                 -->                   **GitHub App**  

ARC runner              -->      authentication	                 -->      Supported Supported  
Setup complexity	    -->      Simpler	                     -->      More setup  
Credential lifetime	    -->      Depends on token expiry policy	 -->      Installation tokens expire after 1 hour  
Identity	            -->      User account	                 -->      Dedicated application  
Production suitability	-->      Possible, with careful controls -->      Generally preferable for automation  

### If you want to use a PAT  
For your repository `vaheed-valaxy/shopverse-gitops`, follow these steps:  

1. Create a fine-grained PAT in GitHub under **Settings → Developer settings → Personal access tokens → Fine-grained tokens.**  
2. Select the appropriate resource owner and grant access to the repository or organization where ARC will register runners.
3. Configure the required permissions:
   - **Repository-level runners**: Administration — Read and write.
   - **Organization-level runners**: Administration — Read and Self-hosted runners — Read and write, according to GitHub's current ARC documentation.
4. Store the token as a Kubernetes Secret in the same namespace as your runner scale set, for example `arc-runners`.
   
Example:  
```bash
kubectl create secret generic pre-defined-secret \
  --namespace=arc-runners \
  --from-literal=github_token='YOUR_PAT'
```

Then reference it in your ARC runner scale set Helm values:  
```yaml
githubConfigSecret: pre-defined-secret
```

**My recommendation**: For a quick learning or development setup, a fine-grained PAT can work. For your production-oriented Shopverse platform, I would use a GitHub App because it provides a dedicated automation identity and avoids tying runner management to a person's account.  

**One final distinction**: the token above authenticates **ARC to GitHub so it can manage runners**. Your workflow's authentication for pushing Helm values commits is a separate concern; it can use **GITHUB_TOKEN**, a GitHub App installation token, or a suitably permissioned PAT.  





```bash
kubectl create namespace arc-runners

kubectl create secret generic shopverse-github-app \
  --namespace arc-runners \
  --from-literal=github_app_id='YOUR_APP_ID' \
  --from-literal=github_app_installation_id='YOUR_INSTALLATION_ID' \
  --from-file=github_app_private_key=./github-app-private-key.pem
```
The secret must exist in the **same namespace as the runner scale set**  

> For a production GitOps setup, I recommend eventually managing this secret through External Secrets Operator
> and AWS Secrets Manager rather than creating it manually. That keeps the secret lifecycle automated without
> storing private key material in Git.











