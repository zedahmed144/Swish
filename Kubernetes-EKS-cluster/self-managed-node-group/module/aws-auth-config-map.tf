# Configure Kubernetes to permit the nodes to register

data "aws_eks_cluster" "selected" {
  name = "morningstar_eks"
}

data "aws_eks_cluster_auth" "selected" {
  name = "morningstar_eks"
}

provider "kubernetes" {
  load_config_file       = false
  host                   = data.aws_eks_cluster.selected.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.selected.token
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<-EOT
      - rolearn: ${module.eks_self_managed_node_group.role_arn}
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
    EOT
  }
}
