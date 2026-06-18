
#!/bin/bash

NAMESPACE="kafka-demo"

echo "Deleting producer job..."
kubectl delete job producer -n $NAMESPACE --ignore-not-found=true

echo "Deleting topic creation job..."
kubectl delete job create-posts-topic -n $NAMESPACE --ignore-not-found=true

echo "Deleting consumer deployment..."
kubectl delete deployment consumer -n $NAMESPACE --ignore-not-found=true

echo "Deleting Kafka StatefulSet..."
kubectl delete statefulset kafka -n $NAMESPACE --ignore-not-found=true

echo "Deleting Kafka service..."
kubectl delete service kafka -n $NAMESPACE --ignore-not-found=true

echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo "Cleanup completed."

