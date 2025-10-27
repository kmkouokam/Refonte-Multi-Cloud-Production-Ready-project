#!/bin/bash
set -e

# Load .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# Terraform directory
TF_DIR="/c/refonte-training/infra"

# Optional: fetch replica counts from Terraform
AWS_REPLICAS=$(terraform -chdir=$TF_DIR output -raw aws_flask_replicas || echo 2)
GCP_REPLICAS=$(terraform -chdir=$TF_DIR output -raw gcp_flask_replicas || echo 2)

echo "AWS Flask Replicas: $AWS_REPLICAS"
echo "GCP Flask Replicas: $GCP_REPLICAS"

# # Choose DB provider
# if [ "$DB_PROVIDER" == "AWS" ]; then
#   DB_HOST="$AWS_DB_HOST"
#   DB_NAME="$AWS_DB_NAME"
#   DB_USER="$AWS_DB_USERNAME"
#   DB_PASSWORD="$AWS_DB_PASSWORD"
# elif [ "$DB_PROVIDER" == "GCP" ]; then
#   DB_HOST="$GCP_DB_HOST"
#   DB_NAME="$GCP_DB_NAME"
#   DB_USER="$GCP_DB_USERNAME"
#   DB_PASSWORD="$GCP_DB_PASSWORD"
# else
#   echo "Unknown DB_PROVIDER: $DB_PROVIDER"
#   exit 1
# fi

# FLASK_SECRET_KEY="$SECRET_KEY"

# echo "Deploying Flask app to $DB_PROVIDER..."
# echo "DB Host: $DB_HOST"
# echo "DB Name: $DB_NAME"
# echo "DB User: $DB_USER"
# echo "DB Password: ******** (hidden)"


# ---------------------------
# Generate override YAMLs
# ---------------------------
cat > "$SCRIPT_DIR/values.override-aws.yaml" <<EOF
replicaCount: $AWS_REPLICAS
db:
  host: "$AWS_DB_HOST"
  name: "$AWS_DB_NAME"
  username: "$AWS_DB_USERNAME"
  password: "$AWS_DB_PASSWORD"
secret: "$SECRET_KEY"
ingress:
  hosts: "$AWS_INGRESS_HOST"
EOF

cat > "$SCRIPT_DIR/values.override-gcp.yaml" <<EOF
replicaCount: $GCP_REPLICAS
db:
  host: "$GCP_DB_HOST"
  name: "$GCP_DB_NAME"
  username: "$GCP_DB_USERNAME"
  password: "$GCP_DB_PASSWORD"
secret: "$SECRET_KEY"
ingress:
  hosts: "$GCP_INGRESS_HOST"
EOF



# ---------------------------
# Function to create/update Kubernetes Secret
# ---------------------------
create_db_secret() {
  local context=$1
  local secret_name=$2
  local db_host=$3
  local db_name=$4
  local db_user=$5
  local db_password=$6
  local secret_key=$7

  echo "🔑 Creating/updating secret '$secret_name' in context $context..."
  kubectl --context "$context" create secret generic "$secret_name" \
    --from-literal=host="$db_host" \
    --from-literal=name="$db_name" \
    --from-literal=username="$db_user" \
    --from-literal=password="$db_password" \
    --from-literal=secret="$secret_key" \
    --namespace default --dry-run=client -o yaml | kubectl apply -f -
}




# ---------------------------
# AWS Deployment
# ---------------------------
if [ "$DB_PROVIDER" == "AWS" ] || [ "$DB_PROVIDER" == "BOTH" ]; then
  echo "Deploying Flask app to AWS..."
  aws eks update-kubeconfig --region us-east-1 --name multi-cloud-cluster
  kubectl config use-context arn:aws:eks:us-east-1:$(aws sts get-caller-identity --query Account --output text):cluster/multi-cloud-cluster

  helm upgrade --install flask-app "$SCRIPT_DIR" \
    --namespace default \
    -f values-aws.yaml \
    -f values.override-aws.yaml \
    --wait
fi

# ---------------------------
# GCP Deployment
# ---------------------------

if [ "$DB_PROVIDER" == "GCP" ] || [ "$DB_PROVIDER" == "BOTH" ]; then
  echo "Deploying Flask app to GCP..."
  gcloud container clusters get-credentials my-gcp-cluster --region us-central1 --project prod-251618-359501
  kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster

  helm upgrade --install flask-app "$SCRIPT_DIR" \
    --namespace default \
    -f values-gcp.yaml \
    -f values.override-gcp.yaml \
    --wait
fi

# ---------------------------
# Cleanup override files
# ---------------------------
rm -f "$SCRIPT_DIR/values.override-aws.yaml" "$SCRIPT_DIR/values.override-gcp.yaml"
echo "Flask app deployed successfully on $DB_PROVIDER!"



# #!/bin/bash

#  set -e

# # # ---------------------------
# # # CONFIGURATION
# # # ---------------------------
#  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#  CHART_DIR="$SCRIPT_DIR"   #  chart is in the same dir as deploy.sh

# # Path to your Terraform infra (master branch)
# TF_DIR="/c/refonte-training/infra"
# # CHART_DIR="./flask_app/helm/flask-app"


# # Optional: fetch desired replica count from Terraform
# AWS_REPLICAS=$(terraform -chdir=$TF_DIR output -raw aws_flask_replicas)
# GCP_REPLICAS=$(terraform -chdir=$TF_DIR output -raw gcp_flask_replicas)

# # Default to 2 if Terraform output is empty
# AWS_REPLICAS=${AWS_REPLICAS:-2}
# GCP_REPLICAS=${GCP_REPLICAS:-2}
# echo "AWS Flask Replicas: $AWS_REPLICAS"
# echo "GCP Flask Replicas: $GCP_REPLICAS"

# # Fetch DB info dynamically from Terraform outputs
# AWS_DB_HOST=$(terraform -chdir=$TF_DIR output -raw aws_db_host)
# GCP_DB_HOST=$(terraform -chdir=$TF_DIR output -raw gcp_db_host)
# DB_USER=$(terraform -chdir=$TF_DIR output -raw aws_db_username)          # dynamic
# # Fetch sensitive DB password without printing it
# DB_PASSWORD=$(terraform -chdir=$TF_DIR output -raw aws_db_password)  # dynamic
# DB_NAME=$(terraform -chdir=$TF_DIR output -raw aws_db_name)          # dynamic
# FLASK_SECRET_KEY="myflasksecretkey" 


# # Optionally, mask DB password in logs
# echo "AWS DB Host: $AWS_DB_HOST"
# echo "GCP DB Host: $GCP_DB_HOST"
# echo "DB User: $DB_USER"
# echo "DB Name: $DB_NAME"
# echo "DB Password: ******** (hidden)"

# # --- Create or update Kubernetes Secret for AWS ---
# # kubectl config use-context arn:aws:eks:us-east-1:435329769674:cluster/multi-cloud-cluster
# # kubectl create secret generic flask-app-db-secret \
# #   --from-literal=username="$DB_USER" \
# #   --from-literal=password="$DB_PASSWORD" \
# #   --from-literal=secret="$FLASK_SECRET_KEY" \
# #   --namespace default --dry-run=client -o yaml | kubectl apply -f -

# # # --- Create or update Kubernetes Secret for GCP ---
# # kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster
# # kubectl create secret generic flask-app-db-secret \
# #   --from-literal=username="$DB_USER" \
# #   --from-literal=password="$DB_PASSWORD" \
# #   --from-literal=secret="$FLASK_SECRET_KEY" \
# #   --namespace default --dry-run=client -o yaml | kubectl apply -f -

# # Create temporary override YAML for AWS
# cat > ./values.override-aws.yaml <<EOF
# db:
#   host: "$AWS_DB_HOST"
#   name: "$DB_NAME"
#   username: "$DB_USER"
#   password: "$DB_PASSWORD"
#   replicas: "$AWS_REPLICAS"
# EOF

# # Create temporary override YAML for GCP
# cat > ./values.override-gcp.yaml <<EOF
# db:
#   host: "$GCP_DB_HOST"
#   name: "$DB_NAME"
#   username: "$DB_USER"
#   password: "$DB_PASSWORD"
#   replicas: "$GCP_REPLICAS"
# EOF

# # echo "🔄 Updating kubeconfig for AWS..."
#  aws eks update-kubeconfig --region us-east-1 --name multi-cloud-cluster
#  kubectl config use-context arn:aws:eks:us-east-1:$(aws sts get-caller-identity --query Account --output text):cluster/multi-cloud-cluster
# # # AWS
# # helm upgrade --install flask-app . \
# #   --namespace default \
# #   -f values-aws.yaml \
# #   -f values.override-aws.yaml

# # # GCP
# # helm upgrade --install flask-app . \
# #   --namespace default \
# #   -f values-gcp.yaml \
# #   -f values.override-gcp.yaml


# # Deploy to AWS
# echo "Deploying Flask app to AWS..."
# kubectl config use-context arn:aws:eks:us-east-1:435329769674:cluster/multi-cloud-cluster
# helm upgrade --install flask-app . \
#   --namespace default \
#   -f values-aws.yaml \
#   --set db.host=terraform-20251026160001638700000006.cjjbcu9s6nug.us-east-1.rds.amazonaws.com \
#   --set db.port=5432 \
#   --set db.username= \
#   --set-string db.password= \
#   --set db.name=postgresdb \
#   --set-string secret=


# # # ---------------------------
# # # GCP Deployment
# # # ---------------------------
# # echo "🔄 Updating kubeconfig for GCP..."
#  gcloud container clusters get-credentials my-gcp-cluster --region us-central1 --project prod-251618-359501
#  kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster

# # Deploy to GCP
# echo "Deploying Flask app to GCP..."
# kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster
# helm upgrade --install flask-app . \
#   --namespace default \
#   -f values-gcp.yaml \
#   --set db.host=34.60.111.42 \
#   --set db.port=5432 \
#   --set db.username= \
#   --set-string db.password= \
#   --set db.name=postgresdb \
#   --set secret=
# # Clean up override files
#  rm  ./values.override-aws.yaml
#  rm ./values.override-gcp.yaml

# echo "Flask app deployed successfully on AWS and GCP!"






# # #!/bin/bash
# # set -e

# # # ---------------------------
# # # CONFIGURATION
# # # ---------------------------
# # SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# # CHART_DIR="$SCRIPT_DIR"   # <-- fixed: chart is in the same dir as deploy.sh

# # # Terraform outputs
# # TF_DIR="/c/refonte-training/infra"

# # AWS_REPLICAS=$(terraform -chdir=$TF_DIR output -raw aws_flask_replicas || echo 2)
# # GCP_REPLICAS=$(terraform -chdir=$TF_DIR output -raw gcp_flask_replicas || echo 2)

# # AWS_DB_HOST=$(terraform -chdir=$TF_DIR output -raw aws_db_host)
# # GCP_DB_HOST=$(terraform -chdir=$TF_DIR output -raw gcp_db_host)
# # DB_USER=$(terraform -chdir=$TF_DIR output -raw aws_db_username)
# # DB_PASSWORD=$(terraform -chdir=$TF_DIR output -raw aws_db_password)
# # DB_NAME=$(terraform -chdir=$TF_DIR output -raw aws_db_name)
# # FLASK_SECRET_KEY="myflasksecretkey"

# # echo "AWS Flask Replicas: $AWS_REPLICAS"
# # echo "GCP Flask Replicas: $GCP_REPLICAS"
# # echo "AWS DB Host: $AWS_DB_HOST"
# # echo "GCP DB Host: $GCP_DB_HOST"
# # echo "DB User: $DB_USER"
# # echo "DB Name: $DB_NAME"
# # echo "DB Password: ******** (hidden)"

# # # ---------------------------
# # # AWS Deployment
# # # ---------------------------
# # echo "🔄 Updating kubeconfig for AWS..."
# # aws eks update-kubeconfig --region us-east-1 --name multi-cloud-cluster
# # kubectl config use-context arn:aws:eks:us-east-1:$(aws sts get-caller-identity --query Account --output text):cluster/multi-cloud-cluster

# # # echo "🔑 Creating/updating AWS secret..."
# # # kubectl create secret generic flask-app-db-secret \
# # #   --from-literal=username="$DB_USER" \
# # #   --from-literal=password="$DB_PASSWORD" \
# # #   --from-literal=secret="$FLASK_SECRET_KEY" \
# # #   -n default --dry-run=client -o yaml | kubectl apply -f -

# # echo "🚀 Deploying Flask app to AWS..."
# # helm upgrade --install flask-app-aws "$CHART_DIR" \
# #   --namespace default \
# #   --set replicaCount=$AWS_REPLICAS \
# #   --set db.host="$AWS_DB_HOST" \
# #   --set db.port=5432 \
# #   --set db.username="$DB_USER" \
# #   --set-string db.password="$DB_PASSWORD" \
# #   --set db.name="$DB_NAME" \
# #   --set secret="$FLASK_SECRET_KEY" \
# #   --wait

# # # ---------------------------
# # # GCP Deployment
# # # ---------------------------
# # echo "🔄 Updating kubeconfig for GCP..."
# # gcloud container clusters get-credentials my-gcp-cluster --region us-central1 --project prod-251618-359501
# # kubectl config use-context gke_prod-251618-359501_us-central1_my-gcp-cluster

# # # echo "🔑 Creating/updating GCP secret..."
# # # kubectl create secret generic flask-app-db-secret \
# # #   --from-literal=username="$DB_USER" \
# # #   --from-literal=password="$DB_PASSWORD" \
# # #   --from-literal=secret="$FLASK_SECRET_KEY" \
# # #   -n default --dry-run=client -o yaml | kubectl apply -f -

# # echo "🚀 Deploying Flask app to GCP..."
# # helm upgrade --install flask-app-gcp "$CHART_DIR" \
# #   --namespace default \
# #   --set replicaCount=$GCP_REPLICAS \
# #   --set db.host="$GCP_DB_HOST" \
# #   --set db.port=5432 \
# #   --set db.username="$DB_USER" \
# #   --set-string db.password="$DB_PASSWORD" \
# #   --set db.name="$DB_NAME" \
# #   --set secret="$FLASK_SECRET_KEY" \
# #   --wait

# # echo "🎉 Flask app deployed successfully on AWS and GCP!"
 







# # # #Must export the following environment variables before running this script:
# # # # AWS_DB_HOST, GCP_DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
# # # # export AWS_DB_HOST=<aws-db-endpoint>
# # # # export GCP_DB_HOST=<gcp-db-endpoint>
# # # # export DB_USER=flask_user
# # # # export DB_PASSWORD=<generated-password>
# # # # export DB_NAME=flaskdb

# # # # ./deploy.sh

# # # #  or

# # # # Export or default DB values
# # # # AWS_DB_HOST=${AWS_DB_HOST:-"replace-with-aws-db-endpoint"}
# # # # GCP_DB_HOST=${GCP_DB_HOST:-"replace-with-gcp-db-endpoint"}
# # # # DB_USER=${DB_USER:-"flask_user"}
# # # # DB_PASSWORD=${DB_PASSWORD:-"replace-with-password"}
# # # # DB_NAME=${DB_NAME:-"flaskdb"}


# # # # ---- AWS Deployment ----
# # # # echo "Deploying Flask app to AWS..."
# # # # helm upgrade --install flask-app . \
# # # #   --namespace default \
# # # #   --set db.host=$AWS_DB_HOST \
# # # #   --set db.user=$DB_USER \
# # # #   --set db.password=$DB_PASSWORD \
# # # #   --set db.name=$DB_NAME \
# # # # #   --set service.type=LoadBalancer \This is set if not done in values-aws.yaml
# # # # #   --set replicaCount=2

# # # # # ---- GCP Deployment ----
# # # # echo "Deploying Flask app to GCP..."
# # # # helm upgrade --install flask-app . \
# # # #   --namespace default \
# # # #   --set db.host=$GCP_DB_HOST \
# # # #   --set db.user=$DB_USER \
# # # #   --set db.password=$DB_PASSWORD \
# # # #   --set db.name=$DB_NAME \
# # # #   --set service.type=ClusterIP \ This is set if not done in values-gcp.yaml
# # # #   --set replicaCount=2
