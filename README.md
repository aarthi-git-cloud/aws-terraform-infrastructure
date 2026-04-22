# AWS Infrastructure as Code — Terraform

Provisions the complete AWS infrastructure that runs the DevOps Demo App:
**VPC → ECR → IAM → EKS (Kubernetes cluster) → S3**

After running this, you will have a live Kubernetes cluster ready to deploy to.

---

## What Gets Created

| Resource | Purpose |
|---|---|
| VPC | Isolated network with public + private subnets across 2 AZs |
| Internet Gateway | Allows public subnets to reach the internet |
| NAT Gateway | Allows EKS nodes (private subnet) to reach internet one-way |
| ECR Repository | Private Docker image registry for the app |
| EKS Cluster | Managed Kubernetes cluster (AWS handles control plane) |
| EKS Node Group | 2x t3.medium EC2 worker nodes |
| IAM Roles | Least-privilege roles for EKS cluster and nodes |
| S3 Bucket | Encrypted app storage bucket |

**Estimated AWS cost:** ~$5–8/day while running (EKS + NAT Gateway).
Destroy when not in use: `terraform destroy`

---

## Prerequisites — Install These First

Open Terminal and run each command. Paste it exactly as shown.

### Step 1 — Install AWS CLI
```bash
# Check if already installed
aws --version

# If not installed, download from:
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# (Download the .pkg for Mac or .msi for Windows)
```

### Step 2 — Configure AWS credentials
```bash
aws configure
```
It will ask for 4 things:
- **AWS Access Key ID** → get from AWS Console → IAM → Users → Your user → Security credentials → Create access key
- **AWS Secret Access Key** → shown once when you create the key above
- **Default region** → type: `ap-south-1`
- **Default output format** → type: `json`

### Step 3 — Install Terraform
```bash
# Check if already installed
terraform --version

# If not installed:
# Mac:     brew install terraform
# Windows: download from https://developer.hashicorp.com/terraform/downloads
# Linux:   sudo apt-get install terraform
```

### Step 4 — Install kubectl
```bash
# Check if already installed
kubectl version --client

# If not installed:
# Mac:     brew install kubectl
# Windows: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Linux:   sudo apt-get install kubectl
```

---

## Step 2 — Bootstrap (One-time setup)

Before Terraform can store state, you need to create an S3 bucket and DynamoDB table manually. This only needs to be done once.

```bash
# Create S3 bucket for Terraform state
# (bucket names must be globally unique — add your name to make it unique)
aws s3 mb s3://devops-demo-terraform-state-aarthi --region ap-south-1

# Enable versioning on the bucket (so you can recover old state)
aws s3api put-bucket-versioning \
  --bucket devops-demo-terraform-state-aarthi \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

Now update `versions.tf` — change this line to match your bucket name:
```hcl
bucket = "devops-demo-terraform-state-aarthi"   # ← your bucket name
```

---

## Step 3 — Deploy Infrastructure

```bash
# 1. Clone this repo
git clone https://github.com/YOUR_USERNAME/aws-terraform-infrastructure.git
cd aws-terraform-infrastructure

# 2. Initialise Terraform (downloads AWS provider, connects to S3 backend)
terraform init

# You should see:
# Terraform has been successfully initialized!

# 3. Preview what will be created (nothing is created yet)
terraform plan

# Read through the output. It shows every resource that will be created.
# Look for: Plan: X to add, 0 to change, 0 to destroy

# 4. Apply — this actually creates the AWS resources
# Type 'yes' when prompted
terraform apply

# This takes 12–15 minutes (EKS cluster takes longest).
# Go get a coffee ☕
```

When it finishes you'll see output like:
```
eks_cluster_name     = "devops-demo-dev-cluster"
ecr_repository_url   = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/devops-demo-app"
next_steps           = ...
```

**Save the `ecr_repository_url` value — you'll need it in Repo 1.**

---

## Step 4 — Connect kubectl to your cluster

```bash
# Run this command (replace cluster name with your output value)
aws eks update-kubeconfig \
  --name devops-demo-dev-cluster \
  --region ap-south-1

# Verify connection
kubectl get nodes

# You should see 2 nodes with status Ready:
# NAME                                        STATUS   ROLES    AGE
# ip-10-0-11-xxx.ap-south-1.compute.internal  Ready    <none>   5m
# ip-10-0-12-xxx.ap-south-1.compute.internal  Ready    <none>   5m
```

---

## Step 5 — Create Kubernetes namespace

```bash
kubectl create namespace production
kubectl create namespace monitoring

# Verify
kubectl get namespaces
```

---

## Destroying Infrastructure (saves cost)

When you're done and want to stop AWS charges:
```bash
terraform destroy
# Type 'yes' when prompted
# This removes everything Terraform created
```

---

## Repository Structure

```
aws-terraform-infrastructure/
├── main.tf               # Wires all modules together
├── variables.tf          # All input variables with descriptions
├── outputs.tf            # Values printed after apply (cluster name, ECR URL etc.)
├── versions.tf           # Terraform version + S3 backend config
└── modules/
    ├── vpc/              # Network: VPC, subnets, IGW, NAT, route tables
    ├── ecr/              # Docker image registry + lifecycle policy
    ├── iam/              # IAM roles for EKS cluster and nodes
    ├── eks/              # EKS cluster + managed node group
    └── s3/               # Encrypted S3 bucket
```

---

## Troubleshooting

**Error: `Error: configuring Terraform AWS Provider: no valid credential sources found`**
→ Run `aws configure` and enter your credentials

**Error: `InvalidClientTokenId`**
→ Your AWS Access Key is wrong. Re-create it in IAM console.

**`kubectl get nodes` shows no nodes**
→ Wait 2–3 more minutes. EKS nodes take time to join.

**Error: S3 bucket already exists**
→ Bucket names are global — add something unique to make it yours.
