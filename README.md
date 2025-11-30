# ECS Microservice Deployment with Terraform and GitHub Actions

This project sets up a simple Python Flask microservice on AWS ECS. Everything is automated - push your code and it gets deployed automatically.

## What's Inside

- A basic Flask app that says "Hello World"
- Terraform scripts to create all the AWS infrastructure
- GitHub Actions workflow that builds Docker images and deploys to ECS

## Getting Started

First things first, you'll need an AWS account and a GitHub repo. Make sure you have AWS credentials ready.

### Step 1: Set Up AWS Credentials

Run this command and enter your AWS keys when prompted:

```bash
aws configure
```

When it asks for the region, use `ap-south-1` (Mumbai). That's where everything will be deployed.

### Step 2: Add Secrets to GitHub

GitHub Actions needs your AWS credentials to deploy. Here's how to add them:

1. Open your repo settings: `https://github.com/manukrishna333/Cloudzenia--CICD/settings/secrets/actions`
2. Click "New repository secret"
3. Add two secrets:
   - `AWS_ACCESS_KEY_ID` - paste your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - paste your AWS secret key

That's it for setup. Now when you push code, GitHub Actions will handle the rest.

### Step 3: Deploy

Just push your code to the `main` branch. The workflow will:
- Create the AWS infrastructure (if it doesn't exist)
- Build your Docker image
- Push it to ECR
- Deploy to ECS

You can watch it happen in the Actions tab. Takes about 5-10 minutes the first time.

## Project Layout

```
.
├── app/                    # Your Flask app lives here
├── terraform/             # All the infrastructure code
├── Dockerfile             # How to build the container
└── .github/workflows/     # The CI/CD magic
```

## Running Locally

Want to test your app before deploying? Here's how:

**Run the Flask app directly:**
```bash
cd app
pip install -r requirements.txt
python main.py
```

Then open `http://localhost:80` in your browser.

**Or build and run with Docker:**
```bash
docker build -t microservice-app .
docker run -p 80:80 microservice-app
```

## Working with Terraform

If you want to manage infrastructure manually (though GitHub Actions does this automatically):

```bash
cd terraform

terraform init      # First time setup
terraform plan      # See what will change
terraform apply     # Create everything
terraform destroy   # Delete everything
```

## Finding Your App's URL

After deployment, you need to find the public IP. Here's a quick way:

```bash
TASK_ARN=$(aws ecs list-tasks --cluster microservice-dev-cluster --region ap-south-1 --query 'taskArns[0]' --output text)
ENI_ID=$(aws ecs describe-tasks --cluster microservice-dev-cluster --tasks $TASK_ARN --region ap-south-1 --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region ap-south-1 --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
echo "Your app is at: http://$PUBLIC_IP"
```

Or just go to AWS Console → ECS → find your cluster → click on the running task → check the Network tab for the public IP.

## Cleaning Up

When you're done testing, destroy everything to avoid charges:

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

## Common Issues

**Can't reach the app?**
- Make sure the ECS task is actually running (check the console)
- Look at CloudWatch logs: `aws logs tail /ecs/microservice-dev-app --follow --region ap-south-1`
- Verify the security group allows traffic on port 80
- Check that the task has a public IP assigned

**Getting "resource already exists" errors?**
- The workflow handles this automatically now
- If you see this locally, the resources exist but Terraform doesn't know about them
- The workflow will skip creating ECR if it already exists

**Task won't start?**
- Check the CloudWatch logs - they'll tell you what's wrong
- Make sure there's a Docker image in ECR
- Verify the IAM roles have the right permissions

## Customizing Things

Want to change something? Edit `terraform/variables.tf`. You can adjust:
- AWS region (currently Mumbai)
- Project name
- Environment name
- VPC network range
- Container port (defaults to 80)
- How much CPU/memory the tasks get
- How many tasks run at once

## What Gets Created

When you deploy, Terraform creates:
- A VPC with public subnets across 2 availability zones
- Internet gateway so things can reach the internet
- Security groups to control traffic
- An ECR repository for your Docker images
- An ECS Fargate cluster
- An ECS service that runs your app
- IAM roles so ECS can pull images and write logs
- CloudWatch log group for application logs

## How the Workflow Works

**First time you deploy:**
Everything gets created from scratch. Infrastructure first, then your app gets built and deployed.

**When you change app code:**
The workflow is smart - it skips infrastructure and just rebuilds your Docker image and redeploys. Much faster.

**When you change Terraform files:**
Infrastructure gets updated, then your app gets rebuilt and redeployed.

## Costs

Running this will cost you:
- ECS Fargate: roughly $0.04 per vCPU-hour and $0.004 per GB-hour
- ECR storage: basically nothing
- CloudWatch logs: pennies
- VPC: free when nothing's running

For a small app running 24/7, expect maybe $10-15 per month. When you're not using it, destroy everything and you won't be charged.

## Notes

- The app runs on port 80, so you don't need to specify a port in the URL
- ECS tasks get new IPs when they restart, so the URL changes
- If you need a stable URL, consider adding a load balancer
- The workflow preserves your ECR repository when you change app code
- Everything runs in public subnets - no NAT gateway needed (saves money)

That's about it. Push your code and watch it deploy!
