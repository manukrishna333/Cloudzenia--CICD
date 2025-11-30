# Terraform ECS Microservice - GitHub Actions CI/CD

Python Flask microservice deployed to AWS ECS using Terraform and GitHub Actions.

## What This Does

- Creates AWS infrastructure (VPC, ECR, ECS) using Terraform
- Builds Docker image and pushes to ECR
- Deploys to ECS Fargate automatically on push to main branch

## Prerequisites

- AWS account
- GitHub repository
- AWS CLI installed (optional, for local testing)

## Setup Steps

### 1. Configure AWS Credentials

**Option A: Using AWS CLI**
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key  
- Default region: `ap-south-1`
- Output format: `json`

**Option B: Manual Configuration**
Create/edit `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

Create/edit `~/.aws/config`:
```ini
[default]
region = ap-south-1
output = json
```

### 2. Add GitHub Secrets

1. Go to your GitHub repo: `https://github.com/manukrishna333/Cloudzenia--CICD/settings/secrets/actions`
2. Click "New repository secret"
3. Add these two secrets:
   - Name: `AWS_ACCESS_KEY_ID`, Value: Your AWS access key
   - Name: `AWS_SECRET_ACCESS_KEY`, Value: Your AWS secret key

### 3. Push Code

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

### 4. Monitor Deployment

1. Go to Actions tab in GitHub
2. Watch the workflow run:
   - Terraform job creates infrastructure
   - Build job builds and pushes Docker image
   - Deploy job updates ECS service

## Project Structure

```
.
├── app/
│   ├── main.py              # Flask app
│   └── requirements.txt     # Python dependencies
├── Dockerfile               # Container build
├── terraform/
│   ├── main.tf             # Provider config
│   ├── variables.tf        # Variables
│   ├── vpc.tf              # VPC setup
│   ├── ecr.tf              # ECR repository
│   ├── ecs.tf              # ECS cluster/service
│   └── iam.tf              # IAM roles
└── .github/workflows/
    └── deploy.yml          # CI/CD pipeline
```

## Local Testing

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

# Initialize
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply

# Destroy everything
terraform destroy
```

## Access Your Service

After deployment, get the public IP:

```bash
# Get cluster name
aws ecs list-clusters

# Get running tasks
aws ecs list-tasks --cluster microservice-dev-cluster

# Get task details (including public IP)
aws ecs describe-tasks --cluster microservice-dev-cluster --tasks <task-id>
```

Or check AWS Console → ECS → Clusters → Tasks → Network tab

Visit: `http://<public-ip>:5000`

## Configuration

Edit `terraform/variables.tf` to change:
- AWS region (default: ap-south-1)
- Project name (default: microservice)
- Environment (default: dev)
- VPC CIDR (default: 10.0.0.0/16)
- Container port (default: 5000)
- ECS task CPU/memory
- Service desired count

## Troubleshooting

**Workflow fails:**
- Check GitHub Secrets are set correctly
- Verify AWS credentials have proper permissions
- Check Actions logs for specific errors

**Service not accessible:**
- Verify ECS task is running (check AWS Console)
- Check security group allows port 5000
- Verify task has public IP assigned

**Terraform errors:**
- Ensure AWS credentials are configured
- Check region is correct (ap-south-1)
- Verify you have permissions to create resources

## AWS Resources Created

- VPC with public/private subnets (2 AZs)
- Internet Gateway and NAT Gateway
- ECR repository
- ECS Fargate cluster
- ECS service with task definition
- IAM roles for ECS
- Security groups
- CloudWatch log group

## Costs

- NAT Gateway: ~$32/month
- ECS Fargate: Pay per use (~$0.04/vCPU-hour, ~$0.004/GB-hour)
- ECR storage: Minimal
- CloudWatch logs: Minimal

To reduce costs, destroy infrastructure when not in use:
```bash
cd terraform
terraform destroy
```
