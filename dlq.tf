variable "main_queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "dlq_name" {
  description = "Name of the Dead Letter Queue (DLQ)"
  type        = string
}

variable "enable_encryption" {
  type = bool
}

variable "profile" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "dlq_retention" {
  type = number
}

variable "receive_count" {
  type = number
}

locals {
  seconds = var.dlq_retention * 86400
}

terraform {
  backend "s3" {
    profile        = "prisma"
    dynamodb_table = "terraform-lock"
    key            = "prisma-test-backup/aws/state.tfstate"
    region         = "us-east-2"
    bucket         = "lean-terraform-sandbox-state"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

data "aws_sqs_queue" "main_queue" {
  name = var.main_queue_name
}

resource "aws_sqs_queue" "dlq" {
  name                       = var.dlq_name
  sqs_managed_sse_enabled    = var.enable_encryption
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = local.seconds
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 60
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [data.aws_sqs_queue.main_queue.arn]
  })
}

resource "aws_sqs_queue_redrive_policy" "main_queue" {
  queue_url = data.aws_sqs_queue.main_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.receive_count
  })
}
