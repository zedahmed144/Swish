# Deploy a self-managed node group in an AWS Region

provider "aws" {
  region  = "us-east-1"
  
}

module "eks_self_managed_node_group" {
  source = "../"

  eks_cluster_name = "morningstar_eks"
  instance_type    = "t3.medium"
  desired_capacity = 2
  min_size         = 2
  max_size         = 4
    
  node_labels = {
    "node.kubernetes.io/node-group" = "node-group-a" # (Optional) node-group name label
  }
}
