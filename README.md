# GitOps Terraform Flux Bootstrap for KBot

This project demonstrates a complete GitOps workflow using Terraform, Flux, and Kind cluster for automated deployment and continuous delivery of a Kubernetes application.

## Project Overview

**Architecture**: Developer → GitHub Actions → Docker Registry → Flux → Kubernetes

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│  Developer  │    │   GitHub     │    │   Kubernetes    │
│             │    │   Actions    │    │    Cluster      │
└─────────────┘    └──────────────┘    └─────────────────┘
       │                  │                     │
       │ 1. Push to       │                     │
       │    develop       │                     │
       ▼                  │                     │
┌─────────────┐           │                     │
│    kbot     │           │                     │
│ repository  │           │                     │
│ (develop)   │           │                     │
└─────────────┘           │                     │
       │                  │                     │
       │ 2. Trigger       │                     │
       ▼                  ▼                     │
┌─────────────┐    ┌──────────────┐             │
│   GitHub    │    │   Build &    │             │
│   Actions   │    │   Push Image │             │
│             │    │              │             │
└─────────────┘    └──────────────┘             │
       │                  │                     │
       │ 3. Update        │                     │
       │ helm/values.yaml │                     │
       ▼                  │                     │
┌─────────────┐           │                     │
│   Updated   │           │                     │
│ helm chart  │           │                     │
│             │           │                     │
└─────────────┘           │                     │
       │                  │                     │
       │ 4. Flux detects  │                     │
       │    changes       │                     │
       ▼                  │                     ▼
┌─────────────┐           │              ┌─────────────────┐
│    Flux     │───────────┼──────────────│   Deploy kbot   │
│ Controller  │ 5. Deploy │              │   Application   │
│             │           │              │                 │
└─────────────┘           │              └─────────────────┘
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Flux CLI](https://fluxcd.io/flux/installation/) (optional)
- GitHub repository for kbot application with develop branch
- GitHub Container Registry or Docker Hub for image storage

## Quick Start

### 1. Clone and Configure

```bash
git clone <your-flux-infrastructure-repo>
cd kbot-flux-infra

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 2. Configure terraform.tfvars

```hcl
# GitHub configuration (repository already created)
github_token = ""  # Leave empty if not using GitHub provider
github_repository_url = "ssh://git@github.com/yourusername/kbot-flux-infra.git"
github_repository_name = "kbot-flux-infra"
create_github_repository = false  # Repository already exists

# Cluster configuration
cluster_name = "flux-demo"
git_branch = "main"

# Application configuration
app_namespace = "kbot"
kbot_repository_url = "https://github.com/yourusername/kbot.git"
kbot_git_branch = "develop"  # Track develop branch
kbot_image_repository = "ghcr.io/yourusername/kbot"
helm_chart_path = "helm"
enable_image_monitoring = false  # Using GitHub Actions for image management
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Verify Deployment

```bash
# Switch to cluster context
kubectl config use-context kind-flux-demo

# Check Flux status
flux get all

# Check application pods
kubectl get pods -n flux-system
kubectl get pods -n kbot
```

## 📁 Repository Structure

### kbot-flux-infra Repository (This Repo)

```
kbot-flux-infra/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf             # Output definitions
├── terraform.tfvars       # Your configuration (DO NOT COMMIT)
├── terraform.tfvars.example # Example configuration (COMMIT)
├── test.sh                # Automated test script (COMMIT)
├── README.md              # This file (COMMIT)
├── .gitignore             # Git ignore rules (COMMIT)
└── clusters/              # Auto-generated by Flux (COMMIT)
    └── flux-demo/
        └── flux-system/   # Flux configuration files
```

### kbot Application Repository Structure

Your kbot repository should have this structure:

```
kbot/
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml          # GitHub Actions updates image.tag here
│   └── templates/
│       ├── deployment.yaml  # Must support command/args from values
│       └── service.yaml
├── .github/workflows/
│   └── ci.yml              # CI/CD pipeline for develop branch
├── Dockerfile
└── main.go
```

## What to Commit vs. What to Ignore

### COMMIT to kbot-flux-infra:

```bash
# Infrastructure code
main.tf
variables.tf
outputs.tf

# Documentation and examples
README.md
terraform.tfvars.example
test.sh

# Flux-generated configuration
clusters/
.gitignore

# Git configuration
.git/
```

### DO NOT COMMIT to kbot-flux-infra:

```bash
# Sensitive configuration
terraform.tfvars          # Contains your actual values

# Terraform state and cache
terraform.tfstate*
.terraform/
.terraform.lock.hcl

# SSH keys and secrets
*.pem
*.key
flux-demo-config
flux-gitops*

# IDE and OS files
.vscode/
.idea/
.DS_Store
```

### Recommended .gitignore:

```gitignore
# Terraform
terraform.tfvars
terraform.tfstate*
.terraform/
.terraform.lock.hcl

# SSH Keys and Secrets
*.pem
*.key
*-config
flux-gitops*

# IDE and OS
.vscode/
.idea/
.DS_Store
*.swp
*.swo

# Logs
*.log
```

## GitOps Workflow

### Automatic Updates Process:

1. **Developer** pushes code to `develop` branch of kbot repository
2. **GitHub Actions** automatically:
   - Builds new Docker image
   - Pushes image to container registry
   - Updates `helm/values.yaml` with new image tag
   - Commits changes back to repository
3. **Flux** monitors kbot repository every 30 seconds
4. **Flux** detects changes in `helm/values.yaml`
5. **Flux** automatically updates Kubernetes deployment with new image

### Example helm/values.yaml (in kbot repo):

```yaml
replicaCount: 1
image:
  registry: "ghcr.io"
  repository: "yourusername/kbot"
  tag: "v1.1.1-abc123"  # GitHub Actions updates this automatically
  os: "linux"
  arch: "amd64"

# Required for proper startup
command: ["./kbot"]
args: ["start"]
restartPolicy: "Always"

secret:
  name: "kbot"
  env: "TELE_TOKEN"
  key: "token"

securityContext:
  privileged: true

service:
  port: 80
  type: ClusterIP
```

### Example deployment.yaml template (in kbot repo):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm.fullname" . }}
spec:
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}-{{ .Values.image.os }}-{{ .Values.image.arch }}"
          {{- if .Values.command }}
          command: {{ .Values.command | toJson }}
          {{- end }}
          {{- if .Values.args }}
          args: {{ .Values.args | toJson }}
          {{- end }}
          # ... rest of configuration
```

## Testing the Workflow

### Automated Test:

```bash
chmod +x test.sh
./test.sh
```

### Manual Verification:

```bash
# Check current image version
kubectl get deployment kbot-helm -n kbot -o jsonpath='{.spec.template.spec.containers[0].image}'

# Make a change in kbot develop branch
# Wait 2-3 minutes for GitHub Actions
# Wait 30-60 seconds for Flux sync

# Verify automatic update
kubectl get deployment kbot-helm -n kbot -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Monitoring and Troubleshooting

### Check Flux Status:

```bash
# Overall status
flux get all

# Specific components
kubectl get gitrepository -n flux-system
kubectl get helmrelease -n kbot
kubectl get pods -n flux-system

# Flux logs
flux logs --follow --tail=10
```

### Common Issues:

**Issue**: HelmRelease fails with "context deadline exceeded"
**Solution**: Check pod logs and ensure proper command/args in Helm template

**Issue**: Flux doesn't detect Git changes
**Solution**: Force reconciliation: `flux reconcile source git kbot-source`

**Issue**: Image not updating automatically
**Solution**: Check GitHub Actions completed and values.yaml updated

### Useful Commands:

```bash
# Force Flux sync
flux reconcile source git kbot-source
flux reconcile helmrelease kbot -n kbot

# Check application logs
kubectl logs -n kbot deployment/kbot-helm --follow

# Debug deployment
kubectl describe deployment kbot-helm -n kbot
kubectl describe helmrelease kbot -n kbot
```

## 🧹 Cleanup

```bash
# Destroy infrastructure
terraform destroy

# Remove Kind cluster
kind delete cluster --name flux-demo

# Clean kubectl contexts
kubectl config delete-context kind-flux-demo
```

## Success Criteria

A successful deployment demonstrates:

✅ **Kind cluster** created and configured  
✅ **Flux installed** and connected to Git repository  
✅ **GitOps workflow** automatically updating application versions  
✅ **kbot application** running with proper configuration  
✅ **Monitoring capabilities** through Flux CLI and kubectl  

## 📚 Additional Resources

- [Flux Documentation](https://fluxcd.io/flux/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy GitOps-ing!**