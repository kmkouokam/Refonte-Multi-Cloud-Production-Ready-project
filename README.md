# 🌩️ Multicloud Flask App Deployment (AWS & GCP)

This project demonstrates a **multicloud deployment pipeline** using **Terraform**, **Helm**, **Docker**, and **Kubernetes (EKS & GKE)**.  
It provisions cloud infrastructure, builds and pushes a Flask application container, and deploys it automatically using Helm.

---
### 1️⃣ Prerequisites

Ensure you have:
- AWS CLI & GCP SDK configured
- Docker Desktop running
- kubectl and Helm installed
- Terraform initialized in the `master` branch


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

1️⃣ Apply Terraform

Deploy your infrastructure (VPC, RDS, etc.) for AWS and GCP:

cd /c/refonte-training/infra
terraform init
terraform apply


This will create all cloud resources.

2️⃣ Export Terraform outputs

Save Terraform outputs to a JSON file (optional, for reference or debugging):

terraform output -json > outputs.json


You can inspect this file to see DB endpoints, replica counts, etc.

Example keys: aws_db_host, aws_flask_replicas, gcp_db_host, etc.

3️⃣ Edit .env

Update the .env file with your dynamic values:

DB_PROVIDER=BOTH

# -----------------------
# AWS Configuration
# -----------------------
aws_db_host=""
aws_db_name=postgresdb
aws_db_username=postgres
aws_db_password=""
aws_ingress_host=""
aws_db_secret_name=flask-app-db-secret-aws
aws_flask_replicas=2

# -----------------------
# GCP Configuration
# -----------------------
gcp_db_host=""
gcp_db_name=postgresdb
gcp_db_username=postgres
gcp_db_password=""
gcp_ingress_host=""
gcp_db_secret_name=flask-app-db-secret-gcp
gcp_flask_replicas=2

# -----------------------
# Flask App Secret
# -----------------------
secret_key=myflasksecret



4️⃣ Run deploy script

Finally, deploy your Flask app to the target cloud(s):

cd /c/refonte-training/flask_app/helm/flask-app
./deploy.sh

### 🧭 Helm Chart Repository
# 1️⃣ Go to your chart directory
cd flask_app/helm/

# 2️⃣ Package the chart
helm package flask-app
# => Output: flask-app-0.1.0.tgz

# 3️⃣ Move the packaged chart to the root of your project
mv flask-app-0.1.0.tgz ../../

# 4️⃣ Go to your project root
cd ../../

# 5️⃣ Move the package into your GitHub Pages docs folder
mv flask-app-0.1.0.tgz Refonte-Multi-Cloud-Production-Ready-project/docs/

# 6️⃣ Go into the docs directory
cd Refonte-Multi-Cloud-Production-Ready-project/docs/

# 7️⃣ Generate or update Helm index.yaml
helm repo index . --url https://kmkouokam.github.io/Refonte-Multi-Cloud-Production-Ready-project/


### 🗂️ Branch master Structure

Refonte-Multi-Cloud-Production-Ready-project/
├── README.md
├── aws_deletion_script/
│   └── delete_vpc.sh
├── gcp_delete_script/
│   └── delete_gcp_vpc.sh
├── environments/
│   ├── aws/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── providers.tf
│   │   ├── terraform.tf
│   │   ├── terraform-rbac.tf
│   │   └── outputs.tf
│   └── gcp/
│       ├── main.tf
│       ├── variables.tf
│       ├── providers.tf
│       ├── terraform.tf
│       ├── terraform-rbac.tf
│       └── outputs.tf
├── modules/
│   ├── vpc/
│   ├── db/
│   ├── security/
│   ├── kubernetes/
│   ├── multi_cloud_vpn/
│   └── helm/
├── terraform.tf
├── outputs.tf
├── variables.tf
├── providers.tf
├── terraform_multicloud_full_guide.md
└── state-backup.json



### 🗂️ Branch flask-app Structure
 Refonte-Multi-Cloud-Production-Ready-project/
├── README.md
├── docs/
│   ├── flask-app-0.1.0.tgz
│   └── index.yaml
├── flask_app/
│   ├── Dockerfile
│   ├── LICENSE
│   ├── Procfile
│   ├── README.md
│   ├── create_db.py
│   ├── db.py
│   ├── flaskr-app.png
│   ├── helm/
│   │   ├── external-dns/
│   │   │   └── external-dns-values.yaml
│   │   └── flask-app/
│   │       ├── Chart.yaml
│   │       ├── deploy.sh
│   │       ├── templates/
│   │       │   ├── _helpers.tpl
│   │       │   ├── deployment.yaml
│   │       │   ├── ingress.yaml
│   │       │   ├── secret.yaml
│   │       │   └── service.yaml
│   │       ├── values.yaml
│   │       ├── values-aws.yaml
│   │       └── values-gcp.yaml
│   ├── k8s/
│   │   └── aws-auth.yaml
│   ├── project/
│   │   ├── app.py
│   │   ├── models.py
│   │   ├── static/
│   │   └── templates/
│   ├── requirements.txt
│   ├── runtime.txt
│   ├── schema.sql
│   └── tests/
│       └── app_test.py
├── image.png
├── mygcp-creds.json
├── terraform.tfstate
└── tfplan



| Cloud Provider | Infra Tool | Database Service | Kubernetes | Ingress Controller           | Monitoring  |
| -------------- | ---------- | ---------------- | ---------- | ---------------------------- | ----------- |
| **AWS**        | Terraform  | Amazon RDS       | EKS        | AWS Load Balancer Controller | CloudWatch  |
| **GCP**        | Terraform  | Cloud SQL        | GKE        | GCP Ingress                  | Stackdriver |

### 🧠 Notes & Best Practices

Each Helm chart is versioned via Chart.yaml

Terraform outputs feed directly into .env for dynamic configuration

Compatible with CI/CD pipelines (GitHub Actions, Jenkins, GitLab CI)

Hosted Helm repo powered by GitHub Pages

Supports multi-environment (dev, prod) deployments

 

 

 

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
