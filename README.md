# Terraform ECS Microservice with GitHub Actions CI/CD

A complete Python microservice deployment setup using Terraform for AWS infrastructure provisioning and GitHub Actions for automated CI/CD pipeline.

## Overview

This project demonstrates:
- A simple Python Flask "Hello World" microservice
- Complete AWS infrastructure provisioning using Terraform (VPC, ECR, ECS, IAM)
- Automated Docker image builds and ECS deployments via GitHub Actions

## Architecture

- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **ECR**: Docker container registry for storing images
- **ECS**: Fargate-based container orchestration
- **Networking**: Internet Gateway, NAT Gateway, Security Groups
- **IAM**: Task execution and task roles for ECS

## Prerequisites

- AWS account with appropriate permissions
- GitHub repository
- GitHub Secrets configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- Terraform >= 1.0 (for local testing)

## Project Structure

```
.
├── app/
│   ├── __init__.py
│   ├── main.py              # Flask hello world application
│   └── requirements.txt     # Python dependencies
├── Dockerfile               # Docker container configuration
├── terraform/
│   ├── main.tf             # Terraform provider configuration
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   ├── vpc.tf              # VPC and networking
│   ├── ecr.tf              # ECR repository
│   ├── ecs.tf              # ECS cluster, service, task definition
│   └── iam.tf              # IAM roles
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions CI/CD workflow
└── README.md
```

## Setup Instructions

### 1. Configure GitHub Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions, and add:

- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

### 2. Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-github-repo-url>
git push -u origin main
```

### 3. GitHub Actions Workflow

The workflow will automatically:
1. **Terraform Job**: Initialize, validate, plan, and apply infrastructure
2. **Build Job**: Build Docker image and push to ECR
3. **Deploy Job**: Update ECS service with new image and wait for deployment

### 4. Access Your Service

After deployment, find your service's public IP:

```bash
# Get ECS task public IP
aws ecs list-tasks --cluster <cluster-name>
aws ecs describe-tasks --cluster <cluster-name> --tasks <task-id>
```

Or check the ECS console in AWS to find the public IP of your running task.

Visit `http://<public-ip>:5000` to see "Hello World"

## Local Development

### Run the application locally

```bash
cd app
pip install -r requirements.txt
python main.py
```

Visit `http://localhost:5000`

### Build Docker image locally

```bash
docker build -t microservice-app .
docker run -p 5000:5000 microservice-app
```

## Terraform Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Plan changes

```bash
terraform plan
```

### Apply infrastructure

```bash
terraform apply
```

### Destroy infrastructure

```bash
terraform destroy
```

## Customization

### Modify Terraform Variables

Edit `terraform/variables.tf` to customize:
- AWS region
- Project name
- Environment
- VPC CIDR
- Container port
- ECS task CPU/memory
- Service desired count

### Modify Application

Edit `app/main.py` to add your application logic.

## Outputs

After Terraform apply, you'll get:
- ECR repository URL
- ECS cluster name
- ECS service name
- VPC ID
- Security group ID

## Cost Considerations

This setup creates:
- VPC with NAT Gateway (~$32/month)
- ECS Fargate tasks (pay per use)
- ECR storage (minimal)
- CloudWatch logs (minimal)

To reduce costs, you can:
- Use a single NAT Gateway
- Scale down ECS service when not in use
- Use smaller instance sizes

## Troubleshooting

### ECS Service not starting

- Check CloudWatch logs: `/ecs/<project-name>-<env>-app`
- Verify security group allows inbound traffic on port 5000
- Check task definition and container health checks

### GitHub Actions failing

- Verify AWS credentials in GitHub Secrets
- Check Terraform outputs are accessible
- Ensure ECR repository exists before build job

### Cannot access service

- Verify ECS task has public IP assigned
- Check security group allows inbound from your IP
- Verify task is running and healthy

## License

MIT

