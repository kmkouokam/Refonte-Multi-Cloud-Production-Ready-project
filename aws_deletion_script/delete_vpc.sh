#!/bin/bash

# to run it ./delete_vpc.sh vpc-0123456789abcdef0
# This script deletes an AWS VPC and all its dependencies.
# It requires AWS CLI to be installed and configured with appropriate permissions.
# Make sure to replace <VPC_ID> with your actual VPC ID.

# Usage: ./delete_vpc.sh <VPC_ID>
# Example: ./delete_vpc.sh vpc-0123456789abcdef0

VPC_ID=$1

if [ -z "$VPC_ID" ]; then
  echo "Usage: $0 <VPC_ID>"
  exit 1
fi

echo "Starting deletion of VPC: $VPC_ID"

# 1. Detach and delete Internet Gateways
for IGW in $(aws ec2 describe-internet-gateways \
    --filters Name=attachment.vpc-id,Values=$VPC_ID \
    --query 'InternetGateways[*].InternetGatewayId' --output text); do
  echo "Detaching Internet Gateway $IGW"
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID
  echo "Deleting Internet Gateway $IGW"
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW
done

# 2. Delete NAT Gateways
for NAT in $(aws ec2 describe-nat-gateways \
    --filter Name=vpc-id,Values=$VPC_ID \
    --query 'NatGateways[*].NatGatewayId' --output text); do
  echo "Deleting NAT Gateway $NAT"
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT
done

# Wait for NAT gateways to be deleted
echo "Waiting for NAT gateways to be deleted..."
aws ec2 wait nat-gateway-deleted --filter Name=vpc-id,Values=$VPC_ID

# 3. Delete Network Interfaces
for ENI in $(aws ec2 describe-network-interfaces \
    --filters Name=vpc-id,Values=$VPC_ID \
    --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text); do
  echo "Deleting network interface $ENI"
  aws ec2 delete-network-interface --network-interface-id $ENI
done

# 4. Delete subnets
for SUBNET in $(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values=$VPC_ID \
    --query 'Subnets[*].SubnetId' --output text); do
  echo "Deleting subnet $SUBNET"
  aws ec2 delete-subnet --subnet-id $SUBNET
done

# 5. Delete non-main route tables
for RT in $(aws ec2 describe-route-tables \
    --filters Name=vpc-id,Values=$VPC_ID \
    --query 'RouteTables[?Associations[?Main==`false`]].RouteTableId' --output text); do
  echo "Deleting route table $RT"
  aws ec2 delete-route-table --route-table-id $RT
done

# 6. Delete security groups (except default)
for SG in $(aws ec2 describe-security-groups \
    --filters Name=vpc-id,Values=$VPC_ID \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
  echo "Deleting security group $SG"
  aws ec2 delete-security-group --group-id $SG
done

# 7. Delete the VPC
echo "Deleting VPC $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "VPC $VPC_ID and all dependencies deleted successfully!"
