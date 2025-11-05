# GitOps Deployment - Flask App

This branch (`gitop`) contains the Kubernetes manifests and GitOps configuration for deploying the Flask application to **AWS EKS** and **GCP GKE** using **ArgoCD**.

## Overview

- **Branch purpose:**  
  The `gitop` branch is solely responsible for **deployment manifests and environment configuration**. It is updated automatically by GitHub Actions whenever a new Docker image is built or environment variables (like DB URLs) change.

- **Deployment strategy:**  
  - AWS and GCP have separate deployment manifests: `deployment-aws.yaml` and `deployment-gcp.yaml`.
  - Secrets are managed separately: `secret-aws.yaml` and `secret-gcp.yaml`.
  - ArgoCD watches this branch and automatically syncs updates to the clusters.

- **Docker images:**  
  - AWS ECR: `123456789012.dkr.ecr.us-east-1.amazonaws.com/flask-app:<git-sha>`  
  - GCP Artifact Registry: `us-central1-docker.pkg.dev/<GCP_PROJECT_ID>/my-repo/flask-app:<git-sha>`

## Folder Structure

 
- **`deployment-aws.yaml`**: Deployment manifest for AWS EKS  
- **`deployment-gcp.yaml`**: Deployment manifest for GCP GKE  
- **`secret-aws.yaml`**: Secrets for AWS RDS  
- **`secret-gcp.yaml`**: Secrets for GCP Cloud SQL  

## How It Works

1. **CI/CD pipeline** (GitHub Actions on `flask-app` branch):
   - Builds Docker images for AWS and GCP.
   - Pushes images to AWS ECR and GCP Artifact Registry.
   - Updates this `gitop` branch with new image tags and DB URLs.

2. **ArgoCD**:
   - Watches the `gitop` branch.
   - Automatically deploys or updates the Flask app in the respective clusters.
   - Handles blue-green deployments and self-healing.

## Useful Links

- [GitHub Repository](https://github.com/kmkouokam/Refonte-Multi-Cloud-Production-Ready-project/tree/gitop)  
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/)  
- [AWS ECR Documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)  
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)

## Notes

- **Do not commit secrets manually.** Secrets are updated automatically via GitHub Actions from Terraform outputs.
- Only Kubernetes manifests and configuration files should reside here.
