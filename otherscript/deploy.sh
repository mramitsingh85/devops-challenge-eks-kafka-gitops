#!/bin/bash

set -e

PROJECT_DIR="/Users/amit.singh/DevOps-Challenge-main"
NAMESPACE="kafka-demo"

cd $PROJECT_DIR

echo "=================================================="
echo "STEP 1 - STARTING COLIMA"
echo "=================================================="

colima start --cpu 4 --memory 10 --disk 60 || true

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

minikube start --driver=docker --memory=7000 --cpus=4

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
echo "STEP 13 - DEPLOYING KAFKA KRaft CLUSTER"
echo "=================================================="

kubectl apply -f k8s/apps/kafka-statefulset.yaml

echo ""
echo "=================================================="
echo "STEP 14 - WAITING FOR KAFKA POD CREATION"
echo "=================================================="

until kubectl get pod kafka-0 -n $NAMESPACE >/dev/null 2>&1
do
  echo "Waiting for kafka-0 pod creation..."
  sleep 5
done

until kubectl get pod kafka-1 -n $NAMESPACE >/dev/null 2>&1
do
  echo "Waiting for kafka-1 pod creation..."
  sleep 5
done

echo ""
echo "=================================================="
echo "STEP 15 - WAITING FOR KAFKA BROKERS READY"
echo "=================================================="

kubectl wait \
  --for=condition=ready pod/kafka-0 \
  -n $NAMESPACE \
  --timeout=600s

kubectl wait \
  --for=condition=ready pod/kafka-1 \
  -n $NAMESPACE \
  --timeout=600s

echo ""
echo "=================================================="
echo "STEP 16 - WAITING FOR KAFKA STABILIZATION"
echo "=================================================="

sleep 40

echo ""
echo "=================================================="
echo "STEP 17 - CHECKING CLUSTER STATUS"
echo "=================================================="

kubectl get svc -n $NAMESPACE
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "=================================================="
echo "STEP 18 - KAFKA LOGS"
echo "=================================================="

kubectl logs kafka-0 -n $NAMESPACE --tail=50 || true

echo ""
echo "=================================================="
echo "STEP 18A - VERIFYING KRaft QUORUM"
echo "=================================================="

kubectl exec -it kafka-0 -n $NAMESPACE -- \
kafka-metadata-quorum \
--bootstrap-server localhost:9092 \
describe --status

echo ""
echo "=================================================="
echo "STEP 18B - CREATING POSTS TOPIC"
echo "=================================================="

kubectl delete job create-posts-topic -n $NAMESPACE --ignore-not-found=true

sleep 5

kubectl apply -f k8s/apps/topic-job.yaml

kubectl wait \
  --for=condition=complete job/create-posts-topic \
  -n $NAMESPACE \
  --timeout=180s

kubectl logs job/create-posts-topic -n $NAMESPACE || true


echo ""
echo "=================================================="
echo "STEP 18C - VERIFYING POSTS TOPIC"
echo "=================================================="

kubectl exec -it kafka-0 -n $NAMESPACE -- \
kafka-topics \
--describe \
--topic posts \
--bootstrap-server localhost:9092

echo ""
echo "=================================================="
echo "STEP 19 - DEPLOYING CONSUMER"
echo "=================================================="

kubectl apply -f k8s/apps/consumer.yaml

echo ""
echo "=================================================="
echo "STEP 20 - WAITING FOR CONSUMER"
echo "=================================================="

kubectl rollout status deployment/consumer -n $NAMESPACE --timeout=300s

echo ""
echo "=================================================="
echo "STEP 21 - DEPLOYING PRODUCER"
echo "=================================================="

kubectl delete job producer -n $NAMESPACE --ignore-not-found=true

sleep 5

kubectl apply -f k8s/apps/producer-job.yaml

echo ""
echo "=================================================="
echo "STEP 22 - WAITING FOR PRODUCER"
echo "=================================================="

sleep 15

echo ""
echo "=================================================="
echo "STEP 23 - PRODUCER LOGS"
echo "=================================================="

kubectl logs job/producer -n $NAMESPACE || true

echo ""
echo "=================================================="
echo "STEP 24 - CONSUMER LOGS"
echo "=================================================="

kubectl logs deployment/consumer -n $NAMESPACE --tail=100 || true

echo ""
echo "=================================================="
echo "STEP 25 - RESOURCE USAGE"
echo "=================================================="

kubectl top pods -n $NAMESPACE || true

echo ""
echo "=================================================="
echo "STEP 26 - VERIFYING KAFKA STATEFULSET"
echo "=================================================="

kubectl get statefulsets -n $NAMESPACE

echo ""
echo "=================================================="
echo "FINAL POD STATUS"
echo "=================================================="

kubectl get pods -n $NAMESPACE

echo ""
echo "Kafka Brokers:"
kubectl get pods -n $NAMESPACE | grep kafka

echo ""
echo "Consumer:"
kubectl get deployments -n $NAMESPACE

echo ""
echo "Producer:"
kubectl get jobs -n $NAMESPACE

echo ""
echo "=================================================="
echo "KAFKA KRaft ENVIRONMENT READY"
echo "=================================================="
