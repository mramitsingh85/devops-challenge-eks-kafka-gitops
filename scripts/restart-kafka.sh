
#!/bin/bash

kubectl rollout restart statefulset kafka -n kafka-demo

kubectl rollout status statefulset kafka -n kafka-demo
