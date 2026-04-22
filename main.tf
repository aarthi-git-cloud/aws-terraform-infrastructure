# ─────────────────────────────────────────────────────────────────────────────
# Root module — wires all infrastructure modules together
#
# Resources created:
#   VPC         — isolated network with public/private subnets across 2 AZs
#   ECR         — Docker image registry for the app
#   IAM         — roles and policies for EKS nodes
#   EKS         — Kubernetes cluster with managed node group
#   S3          — app storage bucket (logs, uploads, etc.)
# ─────────────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  repo_name    = "devops-demo-app"
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "eks" {
  source = "./modules/eks"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_type  = var.eks_node_instance_type
  desired_nodes       = var.eks_desired_nodes
  min_nodes           = var.eks_min_nodes
  max_nodes           = var.eks_max_nodes
  node_role_arn       = module.iam.eks_node_role_arn
  cluster_role_arn    = module.iam.eks_cluster_role_arn
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}
