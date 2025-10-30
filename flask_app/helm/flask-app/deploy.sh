 
#!/bin/bash
set -e

# Load .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
CHART_DIR="$SCRIPT_DIR"   # chart is in the same dir as deploy.sh
NAMESPACE=default


if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# ---------------------------
# Cleanup previous Helm release & secrets
# ---------------------------
echo "🧹 Cleaning up previous Helm release..."
helm uninstall flask-app --namespace $NAMESPACE || echo "No previous release found"

echo "🧹 Deleting old secrets if they exist..."
kubectl delete secret flask-app-db-secret-aws -n $NAMESPACE --ignore-not-found
kubectl delete secret flask-app-db-secret-gcp -n $NAMESPACE --ignore-not-found

# ---------------------------
# Set replicas from .env or default
# ---------------------------
AWS_FLASK_REPLICAS=${AWS_REPLICAS:-2}
GCP_FLASK_REPLICAS=${GCP_REPLICAS:-2}

echo "AWS Flask Replicas: $AWS_FLASK_REPLICAS"
echo "GCP Flask Replicas: $GCP_FLASK_REPLICAS"

# Deploy to AWS
echo "🚀 Deploying Flask app to AWS..."
aws eks update-kubeconfig --name multi-cloud-cluster --region us-east-1

helm upgrade --install flask-app "$CHART_DIR" \
  --set db.awsHost="$AWS_DB_HOST" \
  --set db.awsName="$AWS_DB_NAME" \
  --set db.awsUsername="$AWS_DB_USERNAME" \
  --set db.awsPassword="$AWS_DB_PASSWORD" \
  --set secret="$SECRET_KEY" \
  --set db.provider="$DB_PROVIDER" \
  --set ingress.host="$AWS_INGRESS_HOST" \
  --set replicaCount="$AWS_REPLICAS" \
  --set service.type=LoadBalancer \
  --namespace default

# Deploy to GCP
echo "🚀 Deploying Flask app to GCP..."
gcloud container clusters get-credentials my-gcp-cluster --region us-central1 --project prod-251618-359501

helm upgrade --install flask-app "$CHART_DIR" \
  --set db.gcpHost="$GCP_DB_HOST" \
  --set db.gcpName="$GCP_DB_NAME" \
  --set db.gcpUsername="$GCP_DB_USERNAME" \
  --set db.gcpPassword="$GCP_DB_PASSWORD" \
  --set secret="$SECRET_KEY" \
  --set db.provider="$DB_PROVIDER" \
  --set ingress.host="$GCP_INGRESS_HOST" \
  --set replicaCount="$GCP_REPLICAS" \
  --set service.type=LoadBalancer \
  --namespace default 

 
 
# Determine provider
echo "Flask app deployed successfully on $DB_PROVIDER!"

 




 