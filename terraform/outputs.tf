output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "producer_repo" {
  value = aws_ecr_repository.producer.repository_url
}

output "consumer_repo" {
  value = aws_ecr_repository.consumer.repository_url
}
