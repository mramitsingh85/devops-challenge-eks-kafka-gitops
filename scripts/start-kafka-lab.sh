#!/bin/bash

set -e

PROJECT_DIR="/Users/amit.singh/DevOps-Challenge-main"
NAMESPACE="kafka-demo"

cd $PROJECT_DIR

echo "=================================================="
echo "STEP 1 - STARTING COLIMA"
echo "=================================================="

colima start --cpu 4 --memory 8 --disk 60 || true

echo ""
echo "=================================================="
echo "STEP 2 - WAITING FOR DOCKER"
echo "=================================================="

until docker info >/dev/null 2>&1
do
  echo "Waiting for Docker daemon..."
  sleep 5
done

echo ""
echo "=================================================="
echo "STEP 3 - STARTING MINIKUBE"
echo "=================================================="

minikube start --driver=docker

echo ""
echo "=================================================="
echo "STEP 4 - CONNECTING DOCKER TO MINIKUBE"
echo "=================================================="

eval $(minikube docker-env)

echo ""
echo "=================================================="
echo "STEP 5 - VERIFYING ENVIRONMENT"
echo "=================================================="

kubectl get nodes
docker images || true

echo ""
echo "=================================================="
echo "STEP 6 - WAITING FOR KUBERNETES"
echo "=================================================="

until kubectl cluster-info >/dev/null 2>&1
do
  echo "Waiting for Kubernetes cluster..."
  sleep 5
done

echo ""
echo "=================================================="
echo "STEP 7 - CLEANING OLD ENVIRONMENT"
echo "=================================================="

kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo "Waiting for namespace deletion..."

while kubectl get namespace $NAMESPACE >/dev/null 2>&1
do
  sleep 3
done

echo ""
echo "=================================================="
echo "STEP 8 - CREATING NAMESPACE"
echo "=================================================="

kubectl create namespace $NAMESPACE

echo ""
echo "=================================================="
echo "STEP 9 - REMOVING OLD IMAGES"
echo "=================================================="

docker rmi producer:v1 consumer:v1 || true

echo ""
echo "=================================================="
echo "STEP 10 - BUILDING PRODUCER IMAGE"
echo "=================================================="

docker build -t producer:v1 ./producer

echo ""
echo "=================================================="
echo "STEP 11 - BUILDING CONSUMER IMAGE"
echo "=================================================="

docker build -t consumer:v1 ./consumer

echo ""
echo "=================================================="
echo "STEP 12 - VERIFYING IMAGES"
echo "=================================================="

docker images | grep producer
docker images | grep consumer

echo ""
echo "=================================================="
echo "STEP 13 - DEPLOYING ZOOKEEPER"
echo "=================================================="

kubectl apply -f k8s/apps/zookeeper.yaml

echo ""
echo "=================================================="
echo "STEP 14 - WAITING FOR ZOOKEEPER"
echo "=================================================="

kubectl wait --for=condition=ready pod -l app=zookeeper -n $NAMESPACE --timeout=300s

echo ""
echo "=================================================="
echo "STEP 15 - DEPLOYING KAFKA"
echo "=================================================="

kubectl apply -f k8s/apps/kafka-statefulset.yaml

echo ""
echo "=================================================="
echo "STEP 16 - WAITING FOR KAFKA"
echo "=================================================="

kubectl wait --for=condition=ready pod/kafka-0 -n $NAMESPACE --timeout=600s

echo ""
echo "=================================================="
echo "STEP 17 - CHECKING CLUSTER STATUS"
echo "=================================================="

kubectl get svc -n $NAMESPACE
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "=================================================="
echo "STEP 18 - DEPLOYING CONSUMER"
echo "=================================================="

kubectl apply -f k8s/apps/consumer.yaml

echo ""
echo "=================================================="
echo "STEP 19 - WAITING FOR CONSUMER"
echo "=================================================="

kubectl rollout status deployment/consumer -n $NAMESPACE --timeout=300s

echo ""
echo "=================================================="
echo "STEP 20 - DEPLOYING PRODUCER"
echo "=================================================="

kubectl delete job producer -n $NAMESPACE --ignore-not-found=true

sleep 5

kubectl apply -f k8s/apps/producer-job.yaml

echo ""
echo "=================================================="
echo "STEP 21 - WAITING FOR PRODUCER"
echo "=================================================="

sleep 10

echo ""
echo "=================================================="
echo "STEP 22 - PRODUCER LOGS"
echo "=================================================="

kubectl logs job/producer -n $NAMESPACE || true

echo ""
echo "=================================================="
echo "STEP 23 - CONSUMER LOGS"
echo "=================================================="

kubectl logs deployment/consumer -n $NAMESPACE --tail=100 || true

echo ""
echo "=================================================="
echo "STEP 24 - RESOURCE USAGE"
echo "=================================================="

kubectl top pods -n $NAMESPACE || true

echo ""
echo "=================================================="
echo "FINAL POD STATUS"
echo "=================================================="

kubectl get pods -n $NAMESPACE

echo ""
echo "=================================================="
echo "KAFKA ENVIRONMENT READY"
echo "=================================================="