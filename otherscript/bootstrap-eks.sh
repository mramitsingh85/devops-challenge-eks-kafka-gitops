#!/bin/bash

set -euo pipefail

PROJECT_DIR="$HOME/DevOps-Challenge-main"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

AWS_REGION="ap-south-1"
CLUSTER_NAME="devops-eks"

echo "DEVOPS CHALLENGE - ONE SHOT DEPLOYMENT"

aws sts get-caller-identity

cd "$PROJECT_DIR"

git fetch origin || true
git pull origin main || true

cd "$TERRAFORM_DIR"

rm -rf .terraform

terraform init -upgrade
terraform validate

# Self-heal ECR repositories
if aws ecr describe-repositories --repository-names kafka-producer --region "$AWS_REGION" >/dev/null 2>&1; then
    terraform import aws_ecr_repository.producer kafka-producer >/dev/null 2>&1 || true
fi

if aws ecr describe-repositories --repository-names kafka-consumer --region "$AWS_REGION" >/dev/null 2>&1; then
    terraform import aws_ecr_repository.consumer kafka-consumer >/dev/null 2>&1 || true
fi

# Self-heal CloudWatch log group
if aws logs describe-log-groups --log-group-name-prefix /aws/eks/devops-eks --region "$AWS_REGION" --query 'logGroups[*].logGroupName' --output text | grep -q "/aws/eks/devops-eks/cluster"; then
    aws logs delete-log-group --log-group-name /aws/eks/devops-eks/cluster --region "$AWS_REGION" || true
fi

# Self-heal KMS alias
if aws kms list-aliases --region "$AWS_REGION" --query 'Aliases[*].AliasName' --output text | grep -q "alias/eks/devops-eks"; then
    aws kms delete-alias --alias-name alias/eks/devops-eks --region "$AWS_REGION" || true
fi

terraform plan

read -p "Continue with deployment? (y/n): " choice
if [[ "$choice" != "y" ]]; then
    exit 1
fi

terraform apply -auto-approve

echo "Deployment continues with EKS, ArgoCD and GitOps steps..."
