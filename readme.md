# AWS DevOps CI/CD Project

End-to-end DevOps project demonstrating how to containerize a Node.js application with Docker, provision AWS infrastructure with Terraform, store Docker images in Amazon ECR, and automatically deploy the application to Amazon ECS Fargate using GitHub Actions.

## Architecture

```text
                         ┌──────────────┐
                         │    GitHub    │
                         └──────┬───────┘
                                │
                             git push
                                │
                                ▼
                     ┌────────────────────┐
                     │   GitHub Actions   │
                     └─────────┬──────────┘
                               │
                         docker build
                               │
                               ▼
                     ┌────────────────────┐
                     │    Docker Image    │
                     └─────────┬──────────┘
                               │
                          docker push
                               │
                               ▼
                     ┌────────────────────┐
                     │     Amazon ECR     │
                     │   ecs-demo:latest  │
                     └─────────┬──────────┘
                               │
                           pull image
                               │
                               ▼
                     ┌────────────────────┐
                     │    ECS Fargate     │
                     └─────────┬──────────┘
                               │
                               ▼
                     ┌────────────────────┐
                     │  Running Container │
                     │      :3000         │
                     └─────────┬──────────┘
                               │
                               ▼
                     ┌────────────────────┐
                     │    Node.js App     │
                     └────────────────────┘
```

## Technologies

* AWS
* Terraform
* Docker
* GitHub Actions
* Amazon ECR
* Amazon ECS
* AWS Fargate
* IAM
* VPC
* Security Groups
* CloudWatch
* Git / GitHub
* Node.js

## Project Structure

```text
ecs-demo/
│
├── app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── vpc.tf
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
└── .gitignore
```

## Application

The application is a simple Node.js HTTP server running on port `3000`.

### `app/server.js`

```javascript
const http = require("http");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from GitHub Actions!\n");
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
```

## 1. Run the Application Locally

Navigate to the application directory:

```bash
cd app
```

Build the Docker image:

```bash
docker build -t ecs-demo .
```

Run the container:

```bash
docker run --rm -p 3000:3000 ecs-demo
```

Open:

```text
http://localhost:3000
```

Expected response:

```text
Hello from GitHub Actions!
```

## 2. AWS Infrastructure with Terraform

Terraform is used to provision the AWS infrastructure required by the application.

The infrastructure includes:

* VPC
* Public subnet
* Internet Gateway
* Route table
* Security Group
* Amazon ECR repository
* ECS cluster
* ECS Fargate service
* ECS task definition
* IAM execution role
* CloudWatch Log Group

AWS region:

```text
eu-north-1
```

Application name:

```text
ecs-demo
```

Initialize Terraform:

```bash
cd terraform
terraform init
```

Review the infrastructure plan:

```bash
terraform plan
```

Create the infrastructure:

```bash
terraform apply
```

Confirm with:

```text
yes
```

## 3. Amazon ECR

Amazon ECR is used as the Docker container registry.

Terraform creates the repository:

```hcl
resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

Verify the repository:

```bash
aws ecr describe-repositories \
  --repository-names ecs-demo \
  --region eu-north-1
```

### Login to ECR

```bash
aws ecr get-login-password \
  --region eu-north-1 | \
docker login \
  --username AWS \
  --password-stdin <ECR_REGISTRY>
```

### Build the image

```bash
docker build -t ecs-demo .
```

### Tag the image

```bash
docker tag ecs-demo:latest \
  <ECR_REGISTRY>/ecs-demo:latest
```

### Push the image

```bash
docker push \
  <ECR_REGISTRY>/ecs-demo:latest
```

Verify the image:

```bash
aws ecr describe-images \
  --repository-name ecs-demo \
  --region eu-north-1
```

The image should have:

```text
imageTag: latest
imageStatus: ACTIVE
```

## 4. Amazon ECS Fargate

The ECS task definition uses the image stored in ECR:

```hcl
image = "${aws_ecr_repository.app.repository_url}:latest"
```

The application runs as an ECS Fargate task with:

```text
CPU:       256
Memory:    512 MB
Port:      3000
Desired:   1 task
```

The ECS service is configured with a public IP so the application can be accessed for demonstration purposes.

The Security Group allows inbound traffic on port `3000`.

## 5. GitHub Repository

Initialize Git:

```bash
git init
```

Set the main branch:

```bash
git branch -M main
```

Add the project files:

```bash
git add .
```

Create the first commit:

```bash
git commit -m "Initial ECS deployment setup"
```

Add the GitHub repository:

```bash
git remote add origin https://github.com/YOUR_USERNAME/ecs-demo.git
```

Push the project:

```bash
git push -u origin main
```

## 6. GitHub Actions CI/CD

The CI/CD workflow is located at:

```text
.github/workflows/deploy.yml
```

The workflow is triggered on every push to the `main` branch.

### Deployment pipeline

```text
Git push
   ↓
GitHub Actions
   ↓
Configure AWS credentials
   ↓
Login to Amazon ECR
   ↓
Build Docker image
   ↓
Push image to ECR
   ↓
Force new ECS deployment
   ↓
ECS Fargate runs the new container
```

### Workflow

```yaml
name: Deploy to ECS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-north-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          docker build -t $ECR_REGISTRY/ecs-demo:latest ./app

      - name: Push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          docker push $ECR_REGISTRY/ecs-demo:latest

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster ecs-demo-cluster \
            --service ecs-demo \
            --force-new-deployment
```

## 7. GitHub Secrets

The following secrets must be configured in:

```text
GitHub
→ Settings
→ Secrets and variables
→ Actions
```

Required secrets:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Do not commit AWS credentials to the repository.

## 8. Deploying a New Version

After changing the application:

```bash
git add .
git commit -m "Update application"
git push
```

GitHub Actions automatically:

1. Authenticates with AWS.
2. Logs in to ECR.
3. Builds a new Docker image.
4. Pushes the image to ECR.
5. Forces a new ECS deployment.
6. ECS starts the new container.

## 9. Verify ECS Deployment

Check the ECS service:

```bash
aws ecs describe-services \
  --cluster ecs-demo-cluster \
  --services ecs-demo \
  --region eu-north-1
```

A successful deployment should eventually show:

```text
desired: 1
running: 1
pending: 0
rollout: COMPLETED
```

## 10. Access the Application

Find the running ECS task:

```powershell
$task = aws ecs list-tasks `
  --cluster ecs-demo-cluster `
  --region eu-north-1 `
  --query "taskArns[0]" `
  --output text
```

Find the network interface:

```powershell
$eni = aws ecs describe-tasks `
  --cluster ecs-demo-cluster `
  --tasks $task `
  --region eu-north-1 `
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" `
  --output text
```

Find the public IP:

```powershell
$ip = aws ec2 describe-network-interfaces `
  --network-interface-ids $eni `
  --region eu-north-1 `
  --query "NetworkInterfaces[0].Association.PublicIp" `
  --output text
```

Open:

```text
http://<PUBLIC-IP>:3000
```

Expected response:

```text
Hello from GitHub Actions!
```

## 11. CloudWatch Logs

ECS sends container logs to:

```text
/ecs/ecs-demo
```

The CloudWatch log group is configured by Terraform and has a retention period of 7 days.

## 12. Infrastructure Cleanup

When the project is no longer needed:

```bash
cd terraform
terraform destroy
```

If the ECR repository still contains Docker images, remove the images first and run:

```bash
terraform destroy
```

again.

## 13. What This Project Demonstrates

This project demonstrates an end-to-end DevOps workflow:

```text
Source Code
    ↓
GitHub
    ↓
GitHub Actions
    ↓
Docker Build
    ↓
Amazon ECR
    ↓
Amazon ECS Fargate
    ↓
Running Container
```

Terraform is responsible for provisioning the infrastructure, while GitHub Actions automates application deployment.

## Skills Demonstrated

* Infrastructure as Code with Terraform
* Containerization with Docker
* CI/CD with GitHub Actions
* Container registry management with Amazon ECR
* Container orchestration with Amazon ECS
* Serverless container execution with AWS Fargate
* AWS networking with VPC and subnets
* IAM roles and permissions
* Security Groups
* CloudWatch logging
* Git and GitHub
* Automated application deployments

## CV Description

**AWS DevOps CI/CD Project — Docker, Terraform, ECS, ECR, GitHub Actions**

Built an end-to-end CI/CD pipeline using GitHub Actions, Docker, Terraform, AWS ECR and ECS Fargate, automating container image builds, publishing and deployment. Provisioned AWS networking, IAM, security and CloudWatch logging infrastructure using Terraform and implemented rolling ECS deployments.
