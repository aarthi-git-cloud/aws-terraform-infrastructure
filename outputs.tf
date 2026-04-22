output "vpc_id" {
  description = "VPC ID — reference this in other projects"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR URL — use this in your Jenkinsfile and GitHub Actions"
  value       = module.ecr.repository_url
}

output "s3_bucket_name" {
  description = "S3 bucket for app storage"
  value       = module.s3.bucket_name
}

# Quick-start commands printed after terraform apply
output "next_steps" {
  description = "Run these commands after terraform apply"
  value       = <<-EOT

    ── Next Steps ──────────────────────────────────────────────
    1. Connect kubectl to your new cluster:
       aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ap-south-1

    2. Create the production namespace:
       kubectl create namespace production

    3. Deploy the app:
       kubectl apply -f ../1-cicd-kubernetes-pipeline/k8s/base/deployment.yaml

    4. Get the live URL (wait ~2 min for ALB to provision):
       kubectl get service devops-demo-app-service -n production
    ────────────────────────────────────────────────────────────
  EOT
}
