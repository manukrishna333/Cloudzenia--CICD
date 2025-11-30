#!/bin/bash

# Script to import existing AWS resources into Terraform state
# Run this from the terraform directory

set -e

echo "Importing existing resources into Terraform state..."

# Initialize Terraform first
terraform init

# Get AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-ap-south-1}

echo "AWS Account ID: $ACCOUNT_ID"
echo "Region: $REGION"

# Import ECR Repository
echo "Importing ECR repository..."
terraform import aws_ecr_repository.app microservice-dev-app || echo "ECR repository import failed or already exists"

# Import CloudWatch Log Group
echo "Importing CloudWatch log group..."
terraform import aws_cloudwatch_log_group.app /ecs/microservice-dev-app || echo "CloudWatch log group import failed or already exists"

# Import IAM Roles
echo "Importing IAM roles..."
terraform import aws_iam_role.ecs_task_execution microservice-dev-ecs-task-execution-role || echo "IAM role ecs_task_execution import failed or already exists"
terraform import aws_iam_role.ecs_task microservice-dev-ecs-task-role || echo "IAM role ecs_task import failed or already exists"

# Import IAM Role Policy Attachment
echo "Importing IAM role policy attachments..."
terraform import aws_iam_role_policy_attachment.ecs_task_execution "${ACCOUNT_ID}:role/microservice-dev-ecs-task-execution-role/arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" || echo "IAM policy attachment import failed or already exists"

echo ""
echo "Import completed. Run 'terraform plan' to verify state."

