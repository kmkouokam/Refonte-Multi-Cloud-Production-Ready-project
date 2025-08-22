# Terraform Multi-Cloud Setup Guide

## 📌 Creation Order

### 🔧 Step-by-Step Creation Order

---

### ✅ Step 0: Create Reusable Terraform Modules First

1. **VPC Module**  
   - Accepts input for region, CIDR, subnet types, peering config, etc.

2. **Kubernetes Module**  
   - Accepts parameters for EKS/GKE, node groups, authentication, etc.

3. **Security Module**  
   - Handles IAM roles (AWS), firewall rules (GCP), and encryption (KMS, etc.)

---

### 🌐 Step 1: Provision AWS Infrastructure

1. **AWS VPC with public/private subnets**  
2. **AWS IAM roles & policies**  
3. **AWS RDS (PostgreSQL)**  
4. **AWS EKS cluster**

---

### ☁️ Step 2: Provision GCP Infrastructure

1. **GCP VPC**  
2. **VPC Peering: GCP ↔ AWS**  
3. **GCP GKE cluster**

---

### 🧪 Final Validation

- Ensure cross-cloud DNS and routing
- Test connectivity from EKS ↔ GKE
- Verify IAM/firewalls/encryption


---

## 📁 Project Directory Structure

## 📁 Project Directory Structure

```
multi-cloud-infra/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── backend.tf
├── modules/
│   ├── vpc/
│   ├── kubernetes/
│   └── security/
├── environments/
│   ├── aws/
│   ├── gcp/
│   └── shared/
```

---

### 🔹 environments/aws/main.tf

```hcl
module "aws_vpc" {
  source = "../../modules/vpc"
}
module "aws_security" {
  source = "../../modules/security"
}
module "aws_rds" {
  source = "terraform-aws-modules/rds/aws"
}
module "eks" {
  source = "../../modules/kubernetes"
}
```

---

### 🔹 environments/gcp/main.tf

```hcl
module "gcp_vpc" {
  source = "../../modules/vpc"
}
module "gcp_security" {
  source = "../../modules/security"
}
module "gke" {
  source = "../../modules/kubernetes"
}
```

---

### 🔹 environments/shared/main.tf

```hcl
resource "aws_vpc_peering_connection" "aws_to_gcp" { ... }
resource "google_compute_network_peering" "gcp_to_aws" { ... }
```

---

### ☁️ providers.tf

```hcl
provider "aws" {
  region = var.aws_region
}
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
```

---

### 🧠 Workspaces

- `aws`, `gcp`, `shared`
