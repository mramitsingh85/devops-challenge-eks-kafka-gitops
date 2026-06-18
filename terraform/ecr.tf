resource "aws_ecr_repository" "producer" {
  name         = "kafka-producer"
  force_delete = true
}

resource "aws_ecr_repository" "consumer" {
  name         = "kafka-consumer"
  force_delete = true
}