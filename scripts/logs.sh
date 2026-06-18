
#!/bin/bash

echo "================ PODS ================"
kubectl get pods -n kafka-demo

echo ""
echo "================ SERVICES ================"
kubectl get svc -n kafka-demo

echo ""
echo "================ KAFKA STATEFULSET ================"
kubectl get statefulsets -n kafka-demo

echo ""
echo "================ KAFKA-0 LOGS ================"
kubectl logs kafka-0 -n kafka-demo --tail=50

echo ""
echo "================ KAFKA-1 LOGS ================"
kubectl logs kafka-1 -n kafka-demo --tail=50

echo ""
echo "================ KRaft QUORUM STATUS ================"

kubectl exec -it kafka-0 -n kafka-demo -- \
kafka-metadata-quorum \
--bootstrap-server localhost:9092 \
describe --status

echo ""
echo "================ TOPICS ================"

kubectl exec -it kafka-0 -n kafka-demo -- \
kafka-topics \
--list \
--bootstrap-server localhost:9092

echo ""
echo "================ CONSUMER LOGS ================"
kubectl logs deployment/consumer -n kafka-demo --tail=50 || true

echo ""
echo "================ PRODUCER LOGS ================"
kubectl logs job/producer -n kafka-demo --tail=50 || true

echo ""
echo "================ TOPIC CREATION JOB LOGS ================"
kubectl logs job/create-posts-topic -n kafka-demo --tail=50 || true

