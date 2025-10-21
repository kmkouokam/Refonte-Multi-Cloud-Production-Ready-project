# 🌩️ Multicloud Flask App Deployment (AWS & GCP)

This project demonstrates a **multicloud deployment pipeline** using **Terraform**, **Helm**, **Docker**, and **Kubernetes (EKS & GKE)**.  
It provisions cloud infrastructure, builds and pushes a Flask application container, and deploys it automatically using Helm.

---

## 🏗️ Branch Overview

- **`master` branch (infra)** → Contains Terraform code for provisioning infrastructure:
  - AWS: VPC, EKS Cluster, IAM roles, networking, etc.
  - GCP: VPC, GKE Cluster, IAM configuration, etc.
  - Common monitoring & security modules (CloudWatch, GCP Logging, WAF, etc.)

- **`flask-app` branch** → Contains:
  - Flask web application source code
  - `Dockerfile` for image build
  - Helm chart for Kubernetes deployment
  - `deploy.sh` automation script

---

## 🚀 Deployment Workflow

### 1️⃣ Prerequisites

Ensure you have:
- AWS CLI & GCP SDK configured
- Docker Desktop running
- kubectl and Helm installed
- Terraform initialized in the `master` branch

### 2️⃣ Configure kubeconfig

Before running `deploy.sh`, connect to your Kubernetes cluster:

```bash
# For AWS EKS
aws eks update-kubeconfig --region us-east-1 --name <your-eks-cluster-name>

# For GCP GKE
gcloud container clusters get-credentials <your-gke-cluster-name> --region <your-region> --project <your-project-id>
```

### 3️⃣ Run the deployment script

From the `flask-app` branch:

```bash
./deploy.sh
```

This script will:
- Build and push your Docker image to Docker Hub
- Deploy the Flask app via Helm
- Create a LoadBalancer service (ALB for AWS or GCLB for GCP)
- Output the external IP for access

---

## 📊 Project Flow Overview

The diagram below shows the multicloud deployment flow from Terraform infrastructure provisioning to Helm app deployment:

![Flowchart](https://files.oaiusercontent.com/file-000000002ea4620986dce9dfa1606681/A_flowchart_in_the_digital_image_illustrates_a_mul.png)

---

## ✅ Cleanup

To delete the Helm app and free resources:

```bash
helm uninstall flask-app-default -n default
```

Then destroy the infrastructure (from `master` branch):

```bash
terraform destroy -auto-approve
```

---

## 🧩 Tech Stack

- **Terraform** — Infrastructure as Code (IaC)
- **AWS EKS / GCP GKE** — Kubernetes clusters
- **Docker** — Containerization
- **Helm** — App deployment and configuration
- **Flask** — Python web application
- **CloudWatch / GCP Logging** — Monitoring and observability

---

## 👩🏽‍💻 Author

**Ernestine Désirée Motouom**  
[LinkedIn Profile](https://www.linkedin.com/in/ernestine-desiree-motouom-601716269/)

---
