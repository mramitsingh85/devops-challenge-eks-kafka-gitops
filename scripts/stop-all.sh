#!/bin/bash

set -e

PROJECT_DIR="/Users/amit.singh/DevOps-Challenge-main"
NAMESPACE="kafka-demo"

cd $PROJECT_DIR

echo "=================================================="
echo "STEP 1 - DELETING KAFKA NAMESPACE"
echo "=================================================="

kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo ""
echo "=================================================="
echo "STEP 2 - WAITING FOR CLEANUP"
echo "=================================================="

while kubectl get namespace $NAMESPACE >/dev/null 2>&1
do
  echo "Waiting for namespace deletion..."
  sleep 3
done

echo ""
echo "=================================================="
echo "STEP 3 - STOPPING MINIKUBE"
echo "=================================================="

minikube stop

echo ""
echo "=================================================="
echo "STEP 4 - STOPPING COLIMA"
echo "=================================================="

colima stop

echo ""
echo "=================================================="
echo "ALL SERVICES STOPPED"
echo "=================================================="