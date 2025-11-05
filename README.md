Multi-Cloud Production-Ready Flask App CI/CD Pipeline

This repository demonstrates a multi-cloud CI/CD pipeline for deploying a Flask application to AWS EKS and GCP GKE using GitHub Actions, Terraform, and ArgoCD.

It is designed to automate infrastructure provisioning, Docker image builds, secret injection, and deployment, while supporting multi-cloud best practices.

Branch Structure
Branch	Purpose
master	Terraform infrastructure (VPC, EKS/GKE clusters, DBs, IAM roles, ECR/Artifact Registry)
flask-app	CI workflow: build & push Docker images, fetch Terraform outputs, update GitOps manifests
gitOp	GitOps branch: Kubernetes manifests (k8s/) applied by ArgoCD
1️⃣ Infrastructure Provisioning (master branch)

Push changes to master.

Terraform provisions infrastructure:

terraform init
terraform plan
terraform apply -auto-approve


Provisioned resources:

AWS: VPC, EKS cluster, RDS, IAM roles, ECR repository

GCP: VPC, GKE cluster, Cloud SQL, Artifact Registry

Terraform outputs required by the app:

aws_db_url

gcp_db_url

These outputs are used later by the CI/CD workflow to inject database credentials into Kubernetes secrets.

2️⃣ CI Workflow (flask-app branch)

Trigger: push to flask-app branch

Workflow Steps:

Checkout repository

Fetch Terraform outputs (DB URLs)
Example:

run: |
  echo "aws_db_url=$(terraform output -raw aws_db_url)" >> $GITHUB_ENV
  echo "gcp_db_url=$(terraform output -raw gcp_db_url)" >> $GITHUB_ENV


Authenticate to AWS & GCP

AWS: OIDC role assumption → login to ECR

GCP: Workload identity → login to Artifact Registry

Build Docker image

docker build -t flask-app .
docker tag flask-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/flask-app:${GITHUB_SHA}
docker tag flask-app:latest us-central1-docker.pkg.dev/$GCP_PROJECT_ID/my-repo/flask-app:${GITHUB_SHA}


Push Docker images

Update GitOps branch (gitOp)

Update deployment manifests (k8s/deployment.yaml) with new image tag

Update secrets (k8s/aws-secret.yaml & k8s/gcp-secret.yaml) with DB URLs

Commit and push to gitOp branch

3️⃣ GitOps Deployment (gitOp branch)

ArgoCD Application (flask-app-prod.yaml):

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: flask-app-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "<your-repo>"
    targetRevision: gitOp
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true


ArgoCD watches the gitOp branch.

Automatically applies updated deployment and secrets.

Prunes removed resources and self-heals any drift.

4️⃣ Multi-Cloud Deployment

AWS EKS and GCP GKE deploy the Flask app.

Environment-specific secrets are injected automatically.

Docker images are consistent across both clouds.

ArgoCD ensures clusters remain in sync with the GitOps branch.

5️⃣ Optional: Blue-Green Deployment

Maintain two deployments: deployment-blue.yaml & deployment-green.yaml.

Workflow switches active deployment by updating the manifests.

ArgoCD auto-sync deploys the new active version without downtime.

6️⃣ Pipeline Overview
GitHub Actions (flask-app branch)
 ├─ Build Docker images → Push to AWS ECR & GCP Artifact Registry
 ├─ Fetch Terraform outputs → Update k8s/aws-secret.yaml & k8s/gcp-secret.yaml
 └─ Commit updated manifests → gitOp branch

gitOp branch (GitOps)
 └─ ArgoCD auto-sync → EKS & GKE clusters
      ├─ Apply deployment.yaml
      ├─ Apply secrets
      └─ Self-heal & prune resources


This README shows the full end-to-end CI/CD flow for deploying a Flask application in a multi-cloud production-ready environment. 