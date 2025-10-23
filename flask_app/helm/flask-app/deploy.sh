#!/bin/bash

# Path to your Terraform infra (master branch)
TF_DIR="/c/refonte-training/infra"
# CHART_DIR="./flask_app/helm/flask-app"


# Optional: fetch desired replica count from Terraform
AWS_REPLICAS=$(terraform -chdir=$TF_DIR output -raw aws_flask_replicas)
GCP_REPLICAS=$(terraform -chdir=$TF_DIR output -raw gcp_flask_replicas)

# Default to 2 if Terraform output is empty
AWS_REPLICAS=${AWS_REPLICAS:-2}
GCP_REPLICAS=${GCP_REPLICAS:-2}
echo "AWS Flask Replicas: $AWS_REPLICAS"
echo "GCP Flask Replicas: $GCP_REPLICAS"

# Fetch DB info dynamically from Terraform outputs
AWS_DB_HOST=$(terraform -chdir=$TF_DIR output -raw aws_db_host)
GCP_DB_HOST=$(terraform -chdir=$TF_DIR output -raw gcp_db_host)
DB_USER=$(terraform -chdir=$TF_DIR output -raw aws_db_username)          # dynamic
# Fetch sensitive DB password without printing it
DB_PASSWORD=$(terraform -chdir=$TF_DIR output -raw aws_db_password)  # dynamic
DB_NAME=$(terraform -chdir=$TF_DIR output -raw aws_db_name)          # dynamic
FLASK_SECRET_KEY="myflasksecretkey" 


# Optionally, mask DB password in logs
echo "AWS DB Host: $AWS_DB_HOST"
echo "GCP DB Host: $GCP_DB_HOST"
echo "DB User: $DB_USER"
echo "DB Name: $DB_NAME"
echo "DB Password: ******** (hidden)"

# --- Create or update Kubernetes Secret for AWS ---
kubectl config use-context arn:aws:eks:us-east-1:435329769674:cluster/multi-cloud-cluster
kubectl create secret generic flask-app-db-secret \
  --from-literal=username="$DB_USER" \
  --from-literal=password="$DB_PASSWORD" \
  --from-literal=secret="$FLASK_SECRET_KEY" \
  --namespace default --dry-run=client -o yaml | kubectl apply -f -

# --- Create or update Kubernetes Secret for GCP ---
kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster
kubectl create secret generic flask-app-db-secret \
  --from-literal=username="$DB_USER" \
  --from-literal=password="$DB_PASSWORD" \
  --from-literal=secret="$FLASK_SECRET_KEY" \
  --namespace default --dry-run=client -o yaml | kubectl apply -f -

# Create temporary override YAML for AWS
cat > ./values.override-aws.yaml <<EOF
db:
  host: "$AWS_DB_HOST"
  name: "$DB_NAME"
  username: "$DB_USER"
  password: "$DB_PASSWORD"
  replicas: "$AWS_REPLICAS"
EOF

# Create temporary override YAML for GCP
cat > ./values.override-gcp.yaml <<EOF
db:
  host: "$GCP_DB_HOST"
  name: "$DB_NAME"
  username: "$DB_USER"
  password: "$DB_PASSWORD"
  replicas: "$GCP_REPLICAS"
EOF

# Deploy to AWS
echo "Deploying Flask app to AWS..."
kubectl config use-context arn:aws:eks:us-east-1:435329769674:cluster/multi-cloud-cluster
helm upgrade --install flask-app . --namespace default \
  --set db.host="terraform-20251023140416272500000006.cjjbcu9s6nug.us-east-1.rds.amazonaws.com" \
  --set db.port=5432 \
  --set db.username=cG9zdGdyZXM= \
  --set db.password=TmowPHBzT256Nyl4R0dUaw== \
  --set db.name=postgresdb
  --set secret=bXlmbGFza3NlY3JldGtleQ==


# Deploy to GCP
echo "Deploying Flask app to GCP..."
kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster
helm upgrade --install flask-app . --namespace default \
  --set db.host=136.112.4.195 \
  --set db.port=5432 \
  --set db.username=cG9zdGdyZXM= \
  --set db.password=TmowPHBzT256Nyl4R0dUaw== \
  --set db.name=postgresdb
  --set secret=bXlmbGFza3NlY3JldGtleQ==


# Clean up override files
rm  ./values.override-aws.yaml
rm ./values.override-gcp.yaml

echo "Flask app deployed successfully on AWS and GCP!"



#Must export the following environment variables before running this script:
# AWS_DB_HOST, GCP_DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
# export AWS_DB_HOST=<aws-db-endpoint>
# export GCP_DB_HOST=<gcp-db-endpoint>
# export DB_USER=flask_user
# export DB_PASSWORD=<generated-password>
# export DB_NAME=flaskdb

# ./deploy.sh

#  or

# Export or default DB values
# AWS_DB_HOST=${AWS_DB_HOST:-"replace-with-aws-db-endpoint"}
# GCP_DB_HOST=${GCP_DB_HOST:-"replace-with-gcp-db-endpoint"}
# DB_USER=${DB_USER:-"flask_user"}
# DB_PASSWORD=${DB_PASSWORD:-"replace-with-password"}
# DB_NAME=${DB_NAME:-"flaskdb"}


# ---- AWS Deployment ----
# echo "Deploying Flask app to AWS..."
# helm upgrade --install flask-app . \
#   --namespace default \
#   --set db.host=$AWS_DB_HOST \
#   --set db.user=$DB_USER \
#   --set db.password=$DB_PASSWORD \
#   --set db.name=$DB_NAME \
# #   --set service.type=LoadBalancer \This is set if not done in values-aws.yaml
# #   --set replicaCount=2

# # ---- GCP Deployment ----
# echo "Deploying Flask app to GCP..."
# helm upgrade --install flask-app . \
#   --namespace default \
#   --set db.host=$GCP_DB_HOST \
#   --set db.user=$DB_USER \
#   --set db.password=$DB_PASSWORD \
#   --set db.name=$DB_NAME \
#   --set service.type=ClusterIP \ This is set if not done in values-gcp.yaml
#   --set replicaCount=2
