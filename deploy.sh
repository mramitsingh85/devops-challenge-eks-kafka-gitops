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
echo "Checking Docker..."

if ! docker info >/dev/null 2>&1
then
  echo "Docker not running."

  if command -v colima >/dev/null 2>&1
  then
    echo "Starting Colima..."
    colima start || true
    sleep 15
  fi

  if ! docker info >/dev/null 2>&1
  then
    echo "ERROR: Docker daemon is not available."
    echo "Start Docker Desktop or run: colima start"
    exit 1
  fi
fi

echo "Docker is running."

echo ""
echo "Updating repository..."
cd "$PROJECT_DIR"
git fetch origin main
git pull origin main

echo ""
echo "Terraform deployment..."
cd "$TERRAFORM_DIR"

rm -rf .terraform

terraform init -upgrade
terraform validate
terraform apply -auto-approve

echo ""
echo "Waiting for EKS cluster..."

until aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.status' \
  --output text 2>/dev/null | grep -q ACTIVE
do
  echo "Waiting for EKS cluster..."
  sleep 30
done

echo ""
echo "Configuring kubectl..."

aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

echo ""
echo "Waiting for nodes..."

until kubectl get nodes >/dev/null 2>&1
do
  sleep 10
done

echo ""
echo "Verifying EKS addons..."

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
      --region "$AWS_REGION" || true
  fi
done

for addon in vpc-cni kube-proxy coredns
do
  echo "Waiting for addon: $addon"

  while true
  do
    STATUS=$(aws eks describe-addon \
      --cluster-name "$CLUSTER_NAME" \
      --addon-name "$addon" \
      --region "$AWS_REGION" \
      --query 'addon.status' \
      --output text 2>/dev/null || echo MISSING)

    [ "$STATUS" = "ACTIVE" ] && break

    sleep 20
  done
done

kubectl rollout status daemonset/aws-node \
  -n kube-system \
  --timeout=600s

kubectl wait \
  --for=condition=Ready nodes \
  --all \
  --timeout=900s

echo ""
echo "Building and pushing Docker images..."

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

for REPO in kafka-consumer kafka-producer
do
  aws ecr describe-repositories \
    --repository-names "$REPO" \
    --region "$AWS_REGION" >/dev/null 2>&1 || \
  aws ecr create-repository \
    --repository-name "$REPO" \
    --region "$AWS_REGION"
done

aws ecr get-login-password \
  --region "$AWS_REGION" | docker login \
  --username AWS \
  --password-stdin "$ECR_URL"

echo "Building consumer image..."

docker build \
  --platform linux/amd64 \
  -t kafka-consumer:v1 \
  "$PROJECT_DIR/consumer"

docker tag \
  kafka-consumer:v1 \
  "$ECR_URL/kafka-consumer:v1"

docker push \
  "$ECR_URL/kafka-consumer:v1"

echo "Building producer image..."

docker build \
  --platform linux/amd64 \
  -t kafka-producer:v2 \
  "$PROJECT_DIR/producer"

docker tag \
  kafka-producer:v2 \
  "$ECR_URL/kafka-producer:v2"

docker push \
  "$ECR_URL/kafka-producer:v2"

echo ""
echo "Verifying ECR images..."

aws ecr describe-images \
  --repository-name kafka-consumer \
  --region "$AWS_REGION"

aws ecr describe-images \
  --repository-name kafka-producer \
  --region "$AWS_REGION"

echo ""
echo "Installing ArgoCD..."

kubectl create namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Installing ArgoCD via Helm..."

if ! command -v helm >/dev/null 2>&1
then
  if [[ "$OSTYPE" == "darwin"* ]]
  then
    brew install helm
  else
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
fi

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true

helm repo update

helm upgrade --install argocd \
  argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --wait \
  --timeout 15m

kubectl rollout status \
  deployment/argocd-server \
  -n argocd \
  --timeout=900s

kubectl rollout status \
  deployment/argocd-repo-server \
  -n argocd \
  --timeout=900s

echo ""
echo "Deploying Kafka application..."

kubectl apply \
  -f "$PROJECT_DIR/gitops/applications/kafka-demo.yaml"

echo ""
echo "Waiting for kafka-demo application..."

echo "Waiting for kafka-demo application..."

for i in {1..60}
do
  HEALTH=$(kubectl get application kafka-demo \
    -n argocd \
    -o jsonpath='{.status.health.status}' \
    2>/dev/null || echo Unknown)

  SYNC=$(kubectl get application kafka-demo \
    -n argocd \
    -o jsonpath='{.status.sync.status}' \
    2>/dev/null || echo Unknown)

  echo "Health=$HEALTH Sync=$SYNC"

  if [ "$HEALTH" = "Healthy" ] && [ "$SYNC" = "Synced" ]
  then
      break
  fi

  sleep 15
done

kubectl get application -n argocd

echo ""
echo "Cluster Status"

kubectl get nodes

echo ""
kubectl get pods -A

echo ""
echo "ArgoCD Password"

kubectl get secret \
  argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

echo ""
echo ""

echo ""
echo "Kafka Status"

kubectl get all -n kafka-demo || true

echo ""
echo "ArgoCD Applications"

kubectl get application -n argocd || true

echo "=================================================="
echo "READY"
echo "=================================================="


##################################

echo "=================================================="
echo "READY"
echo "=================================================="

echo ""
echo "================ TEST GUIDE ================"

echo ""
echo "1. ArgoCD Login"
echo "------------------------------------------------"
echo "Start port-forward:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "Open:"
echo "https://localhost:8080"
echo ""
echo "Username: admin"
echo ""
echo "Password Command:"
echo "kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""

echo ""
echo "2. Verify ArgoCD Applications"
echo "------------------------------------------------"
echo "kubectl get application -n argocd"
echo ""
echo "Expected:"
echo "kafka-demo   Synced   Healthy"

echo ""
echo "3. Verify Kafka Pods"
echo "------------------------------------------------"
echo "kubectl get pods -n kafka-demo"

echo ""
echo "4. Watch Consumer Messages"
echo "------------------------------------------------"
echo "kubectl logs deployment/consumer -n kafka-demo -f"

echo ""
echo "5. Manual Kafka Test"
echo "------------------------------------------------"
echo "kubectl exec -it kafka-0 -n kafka-demo -- bash"
echo ""
echo "Inside Kafka Pod:"
echo "kafka-console-producer.sh --broker-list kafka-0.kafka:9092 --topic posts"
echo ""
echo "Type messages:"
echo "hello"
echo "devops"
echo "chatgpt"

echo ""
echo "6. GitOps Self-Healing Test"
echo "------------------------------------------------"
echo "Delete consumer deployment:"
echo "kubectl delete deployment consumer -n kafka-demo"
echo ""
echo "Watch recreation:"
echo "kubectl get pods -n kafka-demo -w"
echo ""
echo "ArgoCD should recreate it automatically."

echo ""
echo "7. Producer Job Test"
echo "------------------------------------------------"
echo "kubectl delete job producer -n kafka-demo"
echo ""
echo "Watch:"
echo "kubectl get jobs -n kafka-demo -w"
echo ""
echo "Check consumer logs again."

echo ""
echo "8. ECR Images"
echo "------------------------------------------------"
echo "aws ecr describe-images --repository-name kafka-consumer --region $AWS_REGION"
echo "aws ecr describe-images --repository-name kafka-producer --region $AWS_REGION"

echo ""
echo "9. Cluster Overview"
echo "------------------------------------------------"
echo "kubectl get nodes"
echo "kubectl get pods -A"
echo "kubectl get svc -A"

echo ""
echo "10. ArgoCD Application Details"
echo "------------------------------------------------"
echo "kubectl describe application kafka-demo -n argocd"

echo ""
echo "=================================================="
echo "DEPLOYMENT COMPLETED SUCCESSFULLY"
echo "=================================================="
