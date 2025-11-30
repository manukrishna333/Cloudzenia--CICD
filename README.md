# Terraform ECS Microservice - GitHub Actions CI/CD

Python Flask microservice deployed to AWS ECS using Terraform and GitHub Actions.

## Overview

- **Infrastructure**: VPC, ECR, ECS Fargate cluster and service
- **CI/CD**: Automated Docker build and deployment via GitHub Actions
- **Region**: Mumbai (ap-south-1)

## Prerequisites

- AWS account with appropriate permissions
- GitHub repository
- AWS CLI (optional, for local testing)

## Quick Start

### 1. Configure AWS Credentials

```bash
aws configure
```
Enter your AWS Access Key ID, Secret Access Key, and set region to `ap-south-1`

### 2. Add GitHub Secrets

1. Go to: `https://github.com/manukrishna333/Cloudzenia--CICD/settings/secrets/actions`
2. Add secrets:
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

### 3. Deploy

Push code to `main` branch - GitHub Actions will automatically:
1. Create/update infrastructure
2. Build Docker image
3. Push to ECR
4. Deploy to ECS

## Project Structure

```
.
├── app/                    # Python Flask application
├── terraform/             # Infrastructure as code
├── Dockerfile             # Container build
└── .github/workflows/     # CI/CD pipelines
```

## Local Development

**Run Flask app:**
```bash
cd app
pip install -r requirements.txt
python main.py
```
Visit: http://localhost:5000

**Build Docker image:**
```bash
docker build -t microservice-app .
docker run -p 5000:5000 microservice-app
```

## Terraform Commands

```bash
cd terraform

terraform init      # Initialize
terraform plan      # Preview changes
terraform apply     # Create infrastructure
terraform destroy   # Delete infrastructure
```

## Access Your Service

**Using check script:**
```bash
cd terraform
./check-deployment.sh
```

**Manual check:**
```bash
# Get public IP
TASK_ARN=$(aws ecs list-tasks --cluster microservice-dev-cluster --region ap-south-1 --query 'taskArns[0]' --output text)
ENI_ID=$(aws ecs describe-tasks --cluster microservice-dev-cluster --tasks $TASK_ARN --region ap-south-1 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region ap-south-1 --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
echo "Access at: http://$PUBLIC_IP:5000"
```

**Via AWS Console:**
1. ECS → Clusters → `microservice-dev-cluster`
2. Services → `microservice-dev-service`
3. Tasks → Running task → Network tab → Public IP
4. Visit: `http://<public-ip>:5000`

## Destroy Infrastructure

**Option 1: GitHub Actions**
1. Actions tab → Destroy Infrastructure workflow
2. Run workflow → Confirm

**Option 2: Local Terraform**
```bash
cd terraform
terraform destroy
```

## Troubleshooting

**Can't access application:**
- Check task is running: `aws ecs describe-services --cluster microservice-dev-cluster --services microservice-dev-service --region ap-south-1`
- Check logs: `aws logs tail /ecs/microservice-dev-app --follow --region ap-south-1`
- Verify security group allows port 5000
- Ensure task has public IP assigned

**Resource already exists error:**
- Workflow automatically cleans up existing resources before creating new ones
- No manual action needed

**Task not starting:**
- Check CloudWatch logs for errors
- Verify Docker image exists in ECR
- Check IAM roles have correct permissions

## Configuration

Edit `terraform/variables.tf` to customize:
- AWS region (default: ap-south-1)
- Project name (default: microservice)
- Environment (default: dev)
- VPC CIDR (default: 30.0.0.0/16)
- Container port (default: 5000)
- ECS task CPU/memory
- Service desired count

## AWS Resources Created

- VPC with public subnets (2 availability zones)
- Internet Gateway
- Security Groups
- ECR repository
- ECS Fargate cluster
- ECS service with task definition
- IAM roles (task execution and task role)
- CloudWatch log group

## Workflow Behavior

**First deployment:**
- Creates all infrastructure
- Builds and pushes Docker image
- Deploys to ECS

**App code changes:**
- Skips infrastructure (no changes needed)
- Builds new Docker image
- Deploys updated application

**Terraform changes:**
- Updates infrastructure
- Rebuilds and redeploys application

## Cost Considerations

- ECS Fargate: Pay per use (~$0.04/vCPU-hour, ~$0.004/GB-hour)
- ECR storage: Minimal
- CloudWatch logs: Minimal
- VPC: No cost when idle

To reduce costs, destroy infrastructure when not in use.
