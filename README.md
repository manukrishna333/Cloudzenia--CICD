# ECS Microservice Deployment with Terraform and GitHub Actions

This project sets up a simple Python Flask microservice on AWS ECS. Everything is automated - push your code and it gets deployed automatically.

## What's Inside

- A basic Flask app that says "Hello World"
- Terraform scripts to create all the AWS infrastructure
- GitHub Actions workflow that builds Docker images and deploys to ECS



### Step 1: Set Up AWS Credentials

Run this command and enter your AWS keys when prompted:

```bash
aws configure
```

When it asks for the region, use `ap-south-1` (Mumbai). That's where everything will be deployed.

### Step 2: Add Secrets to GitHub

GitHub Actions needs your AWS credentials to deploy. Here's how to add them:

1. Open your repo settings: `https://github.com/manukrishna333/Cloudzenia--CICD/settings/secrets/actions`
2. Click "New repository"
3. Add two secrets:
   - `AWS_ACCESS_KEY_ID` - paste your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - paste your AWS secret key


### Step 3: Deploy

Just push your code to the `main` branch. The workflow will:
- Create the AWS infrastructure (if it doesn't exist)
- Build your Docker image
- Push it to ECR
- Deploy to ECS

It takes about 5-10 minutes the first time.



## Working with Terraform

If you want to manage infrastructure manually (though GitHub Actions does this automatically):

```bash
cd terraform

terraform init      # First time setup
terraform plan      # See what will change
terraform apply     # Create everything
terraform destroy   # Delete everything
```

**Using GitHub Actions (easiest):**
1. Go to Actions tab
2. Find "Destroy Infrastructure" workflow
3. Click "Run workflow"
4. Confirm and wait

**Or manually with Terraform:**
```bash
cd terraform
terraform destroy
```

This will delete everything including the ECR repository and all your Docker images.


## Customizing Things

Edit `terraform/variables.tf`. You can adjust:
- AWS region (currently Mumbai)
- Project name
- Environment name
- VPC network range
- Container port (defaults to 80)
- How much CPU/memory the tasks get
- How many tasks run at once

## When you deploy, Terraform creates:
- A VPC with public subnets across 2 availability zones
- Internet gateway so things can reach the internet
- Security groups to control traffic
- An ECR repository for your Docker images
- An ECS Fargate cluster
- An ECS service that runs your app
- IAM roles so ECS can pull images and write logs
- CloudWatch log group for application logs

