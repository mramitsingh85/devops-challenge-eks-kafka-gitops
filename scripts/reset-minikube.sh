#!/bin/bash

set -e

echo "=================================================="
echo "STEP 1 - STOPPING OLD ENVIRONMENT"
echo "=================================================="

minikube stop || true
colima stop || true

echo ""
echo "=================================================="
echo "STEP 2 - DELETING OLD MINIKUBE"
echo "=================================================="

minikube delete --all --purge || true

echo ""
echo "=================================================="
echo "STEP 3 - DELETING OLD COLIMA"
echo "=================================================="

colima delete -f || true

echo ""
echo "=================================================="
echo "STEP 4 - CLEANING OLD FILES"
echo "=================================================="

rm -rf ~/.minikube
rm -rf ~/.kube/cache
rm -rf ~/.kube/http-cache
rm -rf ~/.colima
rm -rf ~/.lima

echo ""
echo "=================================================="
echo "STEP 5 - CLEANING OLD DOCKER DATA"
echo "=================================================="

docker rm -f $(docker ps -aq) 2>/dev/null || true
docker system prune -af --volumes || true

echo ""
echo "=================================================="
echo "STEP 6 - STARTING FRESH COLIMA"
echo "=================================================="

colima start \
  --cpu 4 \
  --memory 7192 \
  --disk 60 \
  --vm-type=qemu \
  --runtime docker

echo ""
echo "=================================================="
echo "STEP 7 - WAITING FOR DOCKER"
echo "=================================================="

until docker info >/dev/null 2>&1
do
  echo "Waiting for Docker daemon..."
  sleep 5
done

echo ""
echo "=================================================="
echo "STEP 8 - STARTING CLEAN MINIKUBE"
echo "=================================================="

minikube start \
  --driver=docker \
  --container-runtime=docker \
  --kubernetes-version=v1.30.0 \
  --cpus=4 \
  --memory=7192 \
  --disk-size=30g

echo ""
echo "=================================================="
echo "STEP 9 - WAITING FOR KUBERNETES API"
echo "=================================================="

until kubectl cluster-info >/dev/null 2>&1
do
  echo "Waiting for Kubernetes API..."
  sleep 10
done

echo ""
echo "=================================================="
echo "STEP 10 - VERIFYING CLUSTER"
echo "=================================================="

kubectl get nodes

echo ""
echo "=================================================="
echo "STEP 11 - VERIFYING SYSTEM PODS"
echo "=================================================="

kubectl get pods -A

echo ""
echo "=================================================="
echo "STEP 12 - WAITING FOR COREDNS"
echo "=================================================="

kubectl wait \
  --for=condition=ready pod \
  -l k8s-app=kube-dns \
  -n kube-system \
  --timeout=300s || true

echo ""
echo "=================================================="
echo "MINIKUBE + COLIMA RESET COMPLETE"
echo "=================================================="

echo ""
echo "Now run:"
echo "./scripts/start-kafka-lab.sh"
echo ""