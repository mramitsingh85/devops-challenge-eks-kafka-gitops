DevOps Challenge - Kafka Microservices on Amazon EKS with GitOps

Overview

This project demonstrates a complete cloud-native DevOps implementation using:

- Amazon EKS (Kubernetes)
- Terraform Infrastructure as Code
- Apache Kafka Cluster
- Python Producer & Consumer Microservices
- Amazon ECR
- ArgoCD GitOps Deployment
- Helm Package Management
- Self-Healing Kubernetes Applications

The solution provisions infrastructure, builds container images, deploys applications, and configures GitOps automation through a single bootstrap script.

---

Architecture
```
                     +------------------+
                     |     GitHub       |
                     | GitOps Manifests |
                     +--------+---------+
                              |
                              v
                      +---------------+
                      |    ArgoCD     |
                      | GitOps Engine |
                      +-------+-------+
                              |
                              v
+---------------------------------------------------------+
|                    Amazon EKS Cluster                   |
|                                                         |
|  +------------+      +----------------------------+     |
|  | Producer   | ---> |        Kafka Cluster       | --->|
|  | Service    |      | Topic: posts               |     |
|  +------------+      +----------------------------+     |
|                                                         |
|                                     +-------------+     |
|                                     | Consumer    |     |
|                                     | Service     |     |
|                                     +-------------+     |
|                                                         |
+---------------------------------------------------------+
                              |
                              v
                    Amazon Elastic Container
                       Registry (ECR)
```
---

Technology Stack

Component| Technology
Cloud Provider| AWS
Container Platform| Kubernetes (EKS)
Infrastructure| Terraform
GitOps| ArgoCD
Messaging| Apache Kafka
Container Registry| Amazon ECR
Packaging| Helm
Programming Language| Python
Container Runtime| Docker / Colima

---

Project Structure
```
DevOps-Challenge-main
│
├── terraform/
│   ├── vpc.tf
│   ├── eks.tf
│   └── outputs.tf
│
├── consumer/
│   ├── Dockerfile
│   └── consumer.py
│
├── producer/
│   ├── Dockerfile
│   └── producer.py
│
├── k8s/
│   ├── kafka-statefulset.yaml
│   ├── consumer.yaml
│   └── producer-job.yaml
│
├── gitops/
│   └── applications/
│       └── kafka-demo.yaml
│
└── bootstrap.sh
```
---

Features

Infrastructure Automation

- Fully automated EKS deployment using Terraform
- VPC, Subnets, IAM Roles, Node Groups
- AWS managed EKS Addons
  - VPC CNI
  - CoreDNS
  - Kube Proxy

Containerization

- Producer and Consumer packaged as Docker images
- Images automatically pushed to Amazon ECR
- Multi-platform image builds

Kafka Deployment

- Kafka deployed as Kubernetes StatefulSet
- Persistent networking
- Topic-based message processing

GitOps with ArgoCD

- Automated application synchronization
- Self-healing deployments
- Declarative Kubernetes manifests
- Git as the single source of truth

Operational Validation

- Cluster health verification
- Addon readiness validation
- Application synchronization checks
- Kafka message flow testing

---

Prerequisites

Install the following tools before deployment:

AWS

aws configure

Terraform

terraform version

Kubectl

kubectl version --client

Docker

docker info

Helm

helm version

Optional (Mac)

brew install colima
colima start

---

Deployment

Clone the repository:

git clone <repository-url>
cd DevOps-Challenge-main

Make the script executable:

chmod +x bootstrap.sh

Run deployment:

./bootstrap.sh

The script automatically performs:

1. Terraform deployment
2. EKS provisioning
3. Kubernetes configuration
4. EKS addon validation
5. ECR repository creation
6. Docker image build
7. Image push to ECR
8. ArgoCD installation
9. GitOps application deployment
10. Health verification

---

Verify Deployment

Check Cluster

kubectl get nodes

Expected:

NAME                           STATUS
ip-xxx.xxx.xxx.xxx             Ready
ip-xxx.xxx.xxx.xxx             Ready

Check Pods

kubectl get pods -A

Check Kafka Namespace

kubectl get all -n kafka-demo

Check ArgoCD Applications

kubectl get application -n argocd

Expected:

kafka-demo    Synced    Healthy

---

Access ArgoCD

Start port forwarding:

kubectl port-forward svc/argocd-server -n argocd 8080:443

Open:

https://localhost:8080

Username:

admin

Retrieve Password:

kubectl get secret argocd-initial-admin-secret \
-n argocd \
-o jsonpath="{.data.password}" | base64 -d

---

Kafka Validation

Watch Consumer Logs

kubectl logs deployment/consumer -n kafka-demo -f

Send Test Messages

kubectl exec -it kafka-0 -n kafka-demo -- bash

Inside Kafka Pod:

kafka-console-producer.sh \
--broker-list kafka-0.kafka:9092 \
--topic posts

Example Messages:

hello
devops
chatgpt

Consumer logs should immediately display the messages.

---

GitOps Self-Healing Demonstration

Delete the Consumer Deployment:

kubectl delete deployment consumer -n kafka-demo

Watch Resources:

kubectl get pods -n kafka-demo -w

ArgoCD automatically recreates the deployment and restores the desired state.

---

ECR Verification

Consumer Images:

aws ecr describe-images \
--repository-name kafka-consumer \
--region ap-south-1

Producer Images:

aws ecr describe-images \
--repository-name kafka-producer \
--region ap-south-1

---

Message  send test (Auto Heal by ArgoCD)

Above is the test that has Autoheal feature via ArgoCD

kubectl delete job producer -n kafka-demo

To check message

kubectl logs deployment/consumer -n kafka-demo -f

reset argo admin pass


kubectl patch secret argocd-secret \
-n argocd \
-p '{"stringData":{
"admin.password":"$2a$10$hmtlh7OIu/kugugWkZikZOivkkxCaheX7q0qHKZTxdYEmH4Um704e",
"admin.passwordMtime":"'"$(date -u +%FT%TZ)"'"
}}'

---

Monitoring Commands

kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get application -n argocd

---

Security Considerations

- IAM Roles for EKS workloads
- Private ECR image storage
- Managed Kubernetes control plane
- GitOps-based change management
- Infrastructure as Code version control

---

CI/CD & GitOps Workflow

```
Developer Commit
       |
       v
    GitHub
       |
       v
    ArgoCD
       |
       v
 Kubernetes
       |
       v
  Application Sync
```
---

Outcome

This project demonstrates:

- End-to-end AWS infrastructure automation
- Kubernetes orchestration on EKS
- Kafka-based event-driven architecture
- Containerized microservices
- GitOps deployment model with ArgoCD
- Automated operational validation
- Production-oriented DevOps practices

---

Author
Amit Singh

