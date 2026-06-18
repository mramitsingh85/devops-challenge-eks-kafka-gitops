#!/bin/bash

set -euo pipefail

PROJECT_DIR="$HOME/DevOps-Challenge-main"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

AWS_REGION="ap-south-1"
CLUSTER_NAME="devops-eks"

echo "=================================================="
echo "BOOTSTRAP DEVOPS CHALLENGE"
echo "=================================================="

aws sts get-caller-identity

echo ""
echo "Updating Git..."
echo ""

cd "$PROJECT_DIR"

git fetch origin main
git pull origin main

echo ""
echo "Terraform Init..."
echo ""

cd "$TERRAFORM_DIR"

rm -rf .terraform

terraform init -upgrade

terraform validate

echo ""
echo "Terraform Apply..."
echo ""

terraform apply -auto-approve

echo ""
echo "Waiting for EKS Cluster..."
echo ""

until aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.status' \
  --output text 2>/dev/null | grep -q ACTIVE
do
  echo "Waiting for EKS..."
  sleep 30
done

echo ""
echo "Configuring kubectl..."
echo ""

aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

echo ""
echo "Verifying EKS Addons..."
echo ""

for addon in vpc-cni kube-proxy coredns
do
  if ! aws eks describe-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name "$addon" \
    --region "$AWS_REGION" >/dev/null 2>&1
  then
    echo "Installing addon: $addon"

    aws eks create-addon \
      --cluster-name "$CLUSTER_NAME" \
      --addon-name "$addon" \
      --region "$AWS_REGION"
  else
    echo "$addon already exists"
  fi
done

echo ""
echo "Waiting for addons..."
echo ""

sleep 60

until kubectl get daemonset aws-node -n kube-system >/dev/null 2>&1
do
  echo "Waiting for aws-node..."
  sleep 15
done

kubectl rollout status daemonset/aws-node \
  -n kube-system \
  --timeout=600s

echo ""
echo "Waiting for nodes..."
echo ""

kubectl wait \
  --for=condition=Ready nodes \
  --all \
  --timeout=900s

kubectl get nodes -o wide

echo ""
echo "Installing ArgoCD..."
echo ""

kubectl create namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait \
  --for=condition=available deployment/argocd-server \
  -n argocd \
  --timeout=900s

echo ""
echo "Deploying GitOps..."
echo ""

kubectl apply \
  -f "$PROJECT_DIR/gitops/applications/kafka-demo.yaml"

echo ""
echo "Waiting for kafka namespace..."
echo ""

until kubectl get ns kafka-demo >/dev/null 2>&1
do
  sleep 10
done

echo ""
echo "Cluster Status"
echo ""

kubectl get nodes

echo ""
kubectl get pods -A

echo ""
echo "ArgoCD Password"
echo ""

kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

echo ""
echo ""

echo "=================================================="
echo "READY"
echo "=================================================="

echo ""
echo "ArgoCD:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"