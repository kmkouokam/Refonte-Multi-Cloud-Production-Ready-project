#!/bin/bash

# Path to your Terraform infra (master branch)
TF_DIR="../multicloud_deployment"

# Optional: fetch desired replica count from Terraform
AWS_REPLICAS=$(terraform -chdir=$TF_DIR output -raw aws_flask_replicas)
GCP_REPLICAS=$(terraform -chdir=$TF_DIR output -raw gcp_flask_replicas)

# Default to 2 if Terraform output is empty
AWS_REPLICAS=${AWS_REPLICAS:-2}
GCP_REPLICAS=${GCP_REPLICAS:-2}
echo "AWS Flask Replicas: $AWS_REPLICAS"
echo "GCP Flask Replicas: $GCP_REPLICAS"

# Fetch DB info dynamically from Terraform outputs
AWS_DB_HOST=$(terraform -chdir=$TF_DIR output -raw aws_db_endpoint)
GCP_DB_HOST=$(terraform -chdir=$TF_DIR output -raw gcp_db_endpoint)
DB_USER=$(terraform -chdir=$TF_DIR output -raw db_user)          # dynamic
# Fetch sensitive DB password without printing it
DB_PASSWORD=$(terraform -chdir=$TF_DIR output -raw db_password)  # dynamic
DB_NAME=$(terraform -chdir=$TF_DIR output -raw db_name)          # dynamic



# Optionally, mask DB password in logs
echo "AWS DB Host: $AWS_DB_HOST"
echo "GCP DB Host: $GCP_DB_HOST"
echo "DB User: $DB_USER"
echo "DB Name: $DB_NAME"
echo "DB Password: ******** (hidden)"

# Create temporary override YAML for AWS
cat > ./helm/flask-app/values.override-aws.yaml <<EOF
db:
  host: "$AWS_DB_HOST"
  name: "$DB_NAME"
  user: "$DB_USER"
  password: "$DB_PASSWORD"
  replicas: "$AWS_REPLICAS"
EOF

# Create temporary override YAML for GCP
cat > ./helm/flask-app/values.override-gcp.yaml <<EOF
db:
  host: "$GCP_DB_HOST"
  name: "$DB_NAME"
  user: "$DB_USER"
  password: "$DB_PASSWORD"
  replicas: "$GCP_REPLICAS"
EOF

# Deploy to AWS
echo "Deploying Flask app to AWS..."
helm upgrade --install flask-app ./helm/flask-app \
  -f ./helm/flask-app/values-aws.yaml \
  -f ./helm/flask-app/values.override-aws.yaml \
  --namespace default

# Deploy to GCP
echo "Deploying Flask app to GCP..."
helm upgrade --install flask-app ./helm/flask-app \
  -f ./helm/flask-app/values-gcp.yaml \
  -f ./helm/flask-app/values.override-gcp.yaml \
  --namespace default

# Clean up override files
rm ./helm/flask-app/values.override-aws.yaml
rm ./helm/flask-app/values.override-gcp.yaml

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
