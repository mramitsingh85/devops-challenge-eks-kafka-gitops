#!/bin/bash

set -e

PROJECT_DIR="/Users/amit.singh/DevOps-Challenge-main"

cd $PROJECT_DIR

eval $(minikube docker-env)

echo "Building consumer image..."

docker build -t consumer:v1 ./consumer

echo "Restarting consumer deployment..."

kubectl rollout restart deployment consumer -n kafka-demo

echo "Consumer logs..."

kubectl logs -f deployment/consumer -n kafka-demo