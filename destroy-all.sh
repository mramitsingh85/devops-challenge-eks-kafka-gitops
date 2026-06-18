#!/bin/bash

set -euo pipefail

export AWS_PAGER=""

AWS_REGION="ap-south-1"
CLUSTER_NAME="devops-eks"

echo "=================================================="
echo "DESTROY DEVOPS CHALLENGE ENVIRONMENT"
echo "=================================================="

aws sts get-caller-identity

echo ""
echo "Deleting EKS Nodegroups..."

NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'nodegroups[*]' --output text 2>/dev/null || true)

for NG in $NODEGROUPS
do
    echo "Deleting nodegroup: $NG"

    aws eks delete-nodegroup \
      --cluster-name "$CLUSTER_NAME" \
      --nodegroup-name "$NG" \
      --region "$AWS_REGION" || true
done

echo ""
echo "Waiting for nodegroups to disappear..."

while true
do
    COUNT=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'length(nodegroups)' --output text 2>/dev/null || echo 0)

    if [ "$COUNT" = "0" ]
    then
        break
    fi

    echo "Remaining nodegroups: $COUNT"
    sleep 30
done

echo ""
echo "Deleting EKS cluster..."

aws eks delete-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" || true

echo ""
echo "Waiting for cluster deletion..."

while aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1
do
    echo "Cluster still deleting..."
    sleep 30
done

echo ""
echo "Deleting ECR repositories..."

aws ecr delete-repository --repository-name kafka-producer --force --region "$AWS_REGION" || true
aws ecr delete-repository --repository-name kafka-consumer --force --region "$AWS_REGION" || true

echo ""
echo "Deleting CloudWatch log group..."

aws logs delete-log-group \
  --log-group-name "/aws/eks/devops-eks/cluster" \
  --region "$AWS_REGION" || true

echo ""
echo "Deleting KMS alias..."

aws kms delete-alias \
  --alias-name "alias/eks/devops-eks" \
  --region "$AWS_REGION" || true

echo ""
echo "Cleaning Terraform state..."

cd ~/DevOps-Challenge-main/terraform

rm -rf .terraform
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl

echo ""
echo "Cleanup Complete"

aws eks list-clusters --region "$AWS_REGION"

