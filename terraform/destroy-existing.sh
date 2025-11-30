#!/bin/bash

# Script to destroy existing AWS resources manually
# Use this if you want to start fresh instead of importing

set -e

echo "WARNING: This will destroy existing AWS resources!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

echo "Destroying existing resources..."

# Delete ECS Service first (if exists)
echo "Deleting ECS service..."
aws ecs update-service --cluster microservice-dev-cluster --service microservice-dev-service --desired-count 0 --region ap-south-1 2>/dev/null || echo "ECS service not found or already deleted"
aws ecs delete-service --cluster microservice-dev-cluster --service microservice-dev-service --region ap-south-1 2>/dev/null || echo "ECS service deletion failed or already deleted"

# Delete ECS Task Definitions
echo "Deleting ECS task definitions..."
aws ecs list-task-definitions --family-prefix microservice-dev-app --region ap-south-1 --query 'taskDefinitionArns[]' --output text | tr '\t' '\n' | while read td; do
  aws ecs deregister-task-definition --task-definition "$td" --region ap-south-1 2>/dev/null || true
done

# Delete ECS Cluster
echo "Deleting ECS cluster..."
aws ecs delete-cluster --cluster microservice-dev-cluster --region ap-south-1 2>/dev/null || echo "ECS cluster not found or already deleted"

# Delete ECR Repository (and all images)
echo "Deleting ECR repository..."
aws ecr delete-repository --repository-name microservice-dev-app --force --region ap-south-1 2>/dev/null || echo "ECR repository not found or already deleted"

# Delete CloudWatch Log Group
echo "Deleting CloudWatch log group..."
aws logs delete-log-group --log-group-name /ecs/microservice-dev-app --region ap-south-1 2>/dev/null || echo "CloudWatch log group not found or already deleted"

# Delete IAM Roles
echo "Deleting IAM roles..."
aws iam detach-role-policy --role-name microservice-dev-ecs-task-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --region ap-south-1 2>/dev/null || true
aws iam delete-role --role-name microservice-dev-ecs-task-execution-role --region ap-south-1 2>/dev/null || echo "IAM role ecs_task_execution not found or already deleted"
aws iam delete-role --role-name microservice-dev-ecs-task-role --region ap-south-1 2>/dev/null || echo "IAM role ecs_task not found or already deleted"

echo ""
echo "Resources deleted. You can now run 'terraform apply' to create fresh infrastructure."

