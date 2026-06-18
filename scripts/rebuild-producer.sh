#!/bin/bash

set -e

PROJECT_DIR="/Users/amit.singh/DevOps-Challenge-main"

cd $PROJECT_DIR

eval $(minikube docker-env)

echo "Building producer image..."

docker build -t producer:v1 ./producer

echo "Deleting old producer jobs..."

kubectl delete jobs --all -n kafka-demo || true

echo "Deploying producer..."

kubectl apply -f k8s/apps/producer-job.yaml

echo "Producer logs..."

kubectl logs -f job/producer -n kafka-demo