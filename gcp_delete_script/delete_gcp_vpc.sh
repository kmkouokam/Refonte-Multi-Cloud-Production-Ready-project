#!/bin/bash

# to run it ./delete_gcp_vpc.sh my-vpc my-project-id
# This script deletes a GCP VPC and all its dependencies.
# It requires gcloud CLI to be installed and authenticated.
# Make sure to replace <VPC_NAME> and <PROJECT_ID> with your actual VPC name and project ID.

# Usage: ./delete_gcp_vpc.sh <VPC_NAME> <PROJECT_ID>
VPC_NAME=$1
PROJECT_ID=$2

if [[ -z "$VPC_NAME" || -z "$PROJECT_ID" ]]; then
    echo "Usage: $0 <VPC_NAME> <PROJECT_ID>"
    exit 1
fi

echo "Deleting all resources in VPC $VPC_NAME in project $PROJECT_ID"

# 1. Delete firewall rules in the VPC
FIREWALLS=$(gcloud compute firewall-rules list --filter="network:$VPC_NAME" --format="value(name)")
for fw in $FIREWALLS; do
    echo "Deleting firewall rule: $fw"
    gcloud compute firewall-rules delete "$fw" --project "$PROJECT_ID" --quiet
done

# 2. Delete routes in the VPC
ROUTES=$(gcloud compute routes list --filter="network:$VPC_NAME" --format="value(name)")
for rt in $ROUTES; do
    echo "Deleting route: $rt"
    gcloud compute routes delete "$rt" --project "$PROJECT_ID" --quiet
done

# 3. Delete subnetworks
SUBNETS=$(gcloud compute networks subnets list --filter="network:$VPC_NAME" --format="value(name)")
for sn in $SUBNETS; do
    echo "Deleting subnet: $sn"
    gcloud compute networks subnets delete "$sn" --network "$VPC_NAME" --project "$PROJECT_ID" --region=$(gcloud compute networks subnets list --filter="name:$sn" --format="value(region)") --quiet
done

# 4. Delete VPC peering connections
PEERS=$(gcloud compute networks peerings list --network="$VPC_NAME" --format="value(name)")
for peer in $PEERS; do
    echo "Deleting peering: $peer"
    gcloud compute networks peerings delete "$peer" --network "$VPC_NAME" --project "$PROJECT_ID" --quiet
done

# 5. Delete the VPC
echo "Deleting VPC: $VPC_NAME"
gcloud compute networks delete "$VPC_NAME" --project "$PROJECT_ID" --quiet

echo "VPC $VPC_NAME and all its dependencies have been deleted."
