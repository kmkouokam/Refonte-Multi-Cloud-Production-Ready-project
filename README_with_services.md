
# Multi-Cloud Terraform Infrastructure

This project provisions a **production-ready multi-cloud infrastructure** using Terraform across **AWS** and **GCP**.  
It follows modular design practices, with reusable modules for VPC, Database, Kubernetes, Security, and Multi-Cloud VPN.

---
## 📂 Project Structure & Service Explanations

- **environments/** – Environment-specific Terraform configs  
  - `aws/` → Defines AWS resources such as VPC, EC2, RDS, IAM, and Kubernetes (EKS).  
  - `gcp/` → Defines GCP resources such as VPC, GKE (Kubernetes), Cloud SQL, and IAM policies.  

- **modules/** – Reusable Terraform modules across clouds:
  - `vpc/` → Creates networking layer (VPC, subnets, route tables, NAT gateways, firewalls/security groups). Ensures secure multi-AZ networking.  
  - `db/` → Provisions managed database services (RDS in AWS, Cloud SQL in GCP). Includes HA (multi-AZ) and encrypted storage.  
  - `kubernetes/` → Sets up Kubernetes clusters (EKS in AWS, GKE in GCP). Supports autoscaling, secure node groups, and workload deployment.  
  - `security/` → Manages IAM users, roles, and policies. Configures security groups, service accounts, and encryption keys for least-privilege security.  
  - `multi_cloud_vpn/` → Configures VPN tunnels between AWS and GCP networks to enable secure inter-cloud communication and hybrid workloads.  

- **providers.tf** – Configures the required providers (AWS and GCP credentials).  
- **variables.tf** – Declares input variables for project customization.  
- **outputs.tf** – Exports key infrastructure values (VPC IDs, DB endpoints, cluster names).  
- **terraform-commands.md** – Quick reference for Terraform commands.  
- **terraform_multicloud_full_guide.md** – In-depth guide to deploying and managing the infrastructure.  
- **terraform.tfstate.d/** – Stores Terraform state per environment (AWS/GCP).  
- **Final Cloud Engineering Assignment.docx** – Original assignment brief.  
- **tfplan** – Terraform plan file (ignored in `.gitignore`).  

---
## 🚀 Deployment Steps

1. Initialize providers and modules:
   ```bash
   terraform init
   ```

2. Select the target environment (AWS or GCP):
   ```bash
   cd environments/aws   # or environments/gcp
   ```

3. Validate configuration:
   ```bash
   terraform validate
   ```

4. Preview changes:
   ```bash
   terraform plan -out=tfplan
   ```

5. Apply infrastructure:
   ```bash
   terraform apply "tfplan"
   ```

---
## 🔒 Security

- Secrets (like `mygcp-creds.json` and `tfplan`) are ignored from Git tracking.  
- IAM policies follow **least-privilege** best practices.  
- Encryption is applied at rest (DB, S3/GCS) and in transit (TLS, VPN).  

---
## 📖 Documentation

- [Terraform Commands](terraform-commands.md)  
- [Multi-Cloud Full Guide](terraform_multicloud_full_guide.md)  

---
## 📥 Download README

[Download README.md](README.md)
