# ── EKS Module ────────────────────────────────────────────────────────────────
# Creates a fully managed Kubernetes cluster with a managed node group.
# EKS handles the control plane — you only manage the worker nodes.

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = var.cluster_role_arn
  version  = "1.29"   # Kubernetes version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true   # Set to false in prod for extra security
  }

  # Useful logs to send to CloudWatch
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [var.cluster_role_arn]
}

# ── Node Group ────────────────────────────────────────────────────────────────
# Managed node group — AWS handles patching and replacing nodes

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  # Automatic node updates — rolls nodes one at a time
  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "app-node"
  }
}

variable "project_name"       { type = string }
variable "environment"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "node_instance_type" { type = string }
variable "desired_nodes"      { type = number }
variable "min_nodes"          { type = number }
variable "max_nodes"          { type = number }
variable "node_role_arn"      { type = string }
variable "cluster_role_arn"   { type = string }

output "cluster_name"     { value = aws_eks_cluster.main.name }
output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
