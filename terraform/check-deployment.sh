#!/bin/bash

# Script to check ECS deployment status and get access information

set -e

REGION=${AWS_REGION:-ap-south-1}
CLUSTER_NAME="microservice-dev-cluster"
SERVICE_NAME="microservice-dev-service"

echo "Checking ECS deployment status..."
echo "=================================="
echo ""

# Check if cluster exists
echo "1. Checking ECS cluster..."
CLUSTER_EXISTS=$(aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query 'clusters[0].clusterName' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$CLUSTER_EXISTS" == "NOT_FOUND" ] || [ "$CLUSTER_EXISTS" == "None" ]; then
  echo "   ERROR: Cluster '$CLUSTER_NAME' not found"
  exit 1
else
  echo "   ✓ Cluster found: $CLUSTER_NAME"
fi

# Check service status
echo ""
echo "2. Checking ECS service..."
SERVICE_STATUS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].status' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$SERVICE_STATUS" == "NOT_FOUND" ] || [ "$SERVICE_STATUS" == "None" ]; then
  echo "   ERROR: Service '$SERVICE_NAME' not found"
  exit 1
else
  echo "   ✓ Service status: $SERVICE_STATUS"
  
  DESIRED_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].desiredCount' --output text)
  RUNNING_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].runningCount' --output text)
  echo "   Desired tasks: $DESIRED_COUNT"
  echo "   Running tasks: $RUNNING_COUNT"
fi

# Get running tasks
echo ""
echo "3. Checking running tasks..."
TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --region $REGION --query 'taskArns[]' --output text 2>/dev/null || echo "")

if [ -z "$TASK_ARNS" ]; then
  echo "   WARNING: No running tasks found"
  echo ""
  echo "   Checking recent task failures..."
  aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status STOPPED --region $REGION --max-items 5 --query 'taskArns[]' --output text | head -n 1 | while read task_arn; do
    if [ -n "$task_arn" ]; then
      echo "   Recent stopped task: $task_arn"
      aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $task_arn --region $REGION --query 'tasks[0].stoppedReason' --output text
    fi
  done
  exit 1
else
  echo "   ✓ Found $(echo $TASK_ARNS | wc -w | tr -d ' ') running task(s)"
fi

# Get task details and public IP
echo ""
echo "4. Getting task details..."
FIRST_TASK=$(echo $TASK_ARNS | awk '{print $1}')
TASK_DETAILS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $FIRST_TASK --region $REGION --query 'tasks[0]' --output json)

TASK_STATUS=$(echo $TASK_DETAILS | jq -r '.lastStatus')
HEALTH_STATUS=$(echo $TASK_DETAILS | jq -r '.healthStatus // "N/A"')
PUBLIC_IP=$(echo $TASK_DETAILS | jq -r '.attachments[0].details[] | select(.name=="networkInterfaceId") | .value' | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text 2>/dev/null || echo "NOT_FOUND")

echo "   Task status: $TASK_STATUS"
echo "   Health status: $HEALTH_STATUS"

if [ "$PUBLIC_IP" != "NOT_FOUND" ] && [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
  echo ""
  echo "=================================="
  echo "✓ DEPLOYMENT SUCCESSFUL"
  echo "=================================="
  echo ""
  echo "Your application is accessible at:"
  echo "  http://$PUBLIC_IP:5000"
  echo ""
  echo "Health check endpoint:"
  echo "  http://$PUBLIC_IP:5000/health"
  echo ""
  
  # Test connectivity
  echo "Testing connectivity..."
  if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$PUBLIC_IP:5000" | grep -q "200\|Hello"; then
    echo "✓ Application is responding!"
  else
    echo "⚠ Application may not be responding yet. Please wait a few moments and try again."
  fi
else
  echo ""
  echo "=================================="
  echo "⚠ ISSUE DETECTED"
  echo "=================================="
  echo ""
  echo "Public IP not found. Checking security group..."
  
  # Get security group ID
  SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=microservice-dev-ecs-tasks-sg" --region $REGION --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")
  
  if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "Security Group ID: $SG_ID"
    echo ""
    echo "Checking security group rules..."
    aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --query 'SecurityGroups[0].IpPermissions[]' --output json | jq -r '.[] | "  Port: \(.FromPort)-\(.ToPort), Protocol: \(.IpProtocol), Source: \(.IpRanges[0].CidrIp // "N/A")"'
  fi
  
  echo ""
  echo "Please check:"
  echo "1. ECS task is running (check AWS Console)"
  echo "2. Security group allows inbound traffic on port 5000"
  echo "3. Task has public IP assigned"
  echo "4. Application is listening on port 5000"
fi

echo ""
echo "=================================="
echo "CloudWatch Logs:"
echo "=================================="
echo "View logs: aws logs tail /ecs/microservice-dev-app --follow --region $REGION"
echo ""

