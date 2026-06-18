#!/bin/bash

set -e

PROJECT_DIR="$HOME/DevOps-Challenge-main"

echo "=================================================="
echo "VERIFY AWS ACCOUNT"
echo "=================================================="

aws sts get-caller-identity

echo ""
echo "=================================================="
echo "MOVE TO TERRAFORM DIRECTORY"
echo "=================================================="

cd "$PROJECT_DIR/terraform"

echo ""
echo "=================================================="
echo "INITIALIZING TERRAFORM PROVIDERS"
echo "=================================================="

terraform init

echo ""
echo "=================================================="
echo "VERIFY TERRAFORM STATE"
echo "=================================================="

terraform state list || true

echo ""
echo "=================================================="
echo "DESTROYING EKS INFRASTRUCTURE"
echo "=================================================="

terraform destroy -auto-approve

echo ""
echo "=================================================="
echo "VERIFY EKS DELETION"
echo "=================================================="

aws eks list-clusters

echo ""
echo "=================================================="
echo "VERIFY RUNNING EC2 INSTANCES"
echo "=================================================="

aws ec2 describe-instances 
--filters Name=instance-state-name,Values=running 
--query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]' 
--output table

echo ""
echo "=================================================="
echo "VERIFY ECR REPOSITORIES (PRESERVED)"
echo "=================================================="

aws ecr describe-repositories 
--region ap-south-1 
--query 'repositories[*].repositoryName'

echo ""
echo "=================================================="
echo "AWS COST STOPPED"
echo "=================================================="