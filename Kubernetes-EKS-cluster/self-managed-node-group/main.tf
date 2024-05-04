# Amazon EKS cluster data
data "aws_eks_cluster" "selected" {
  name = var.eks_cluster_name
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["morningstar_vpc"]
  }
}

# EC2 instance type data
data "aws_ec2_instance_type" "selected" {
  instance_type = var.instance_type
}

# Amazon public subnets data
data "aws_subnets" "public-subnets" {
    filter {
        name = "tag:Name"
        values = ["morningstar_public_subnet"]
    }
}

resource "aws_autoscaling_group" "eks_self_managed_node_group" {
  name = "${var.eks_cluster_name}-${local.node_group_name}"

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  vpc_zone_identifier = data.aws_subnets.public-subnets.ids

  
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.eks_self_managed_nodes.id
      }
      
    }
  }

  tags = concat(
    [
      for tag, value in var.tags : {
        key                 = tag
        value               = value
        propagate_at_launch = true
      }
    ],
    [
      {
        key                 = "Name"
        value               = "${var.eks_cluster_name}-${local.node_group_name}"
        propagate_at_launch = true
      },
      {
        key                 = "kubernetes.io/cluster/${var.eks_cluster_name}"
        value               = "owned"
        propagate_at_launch = true
      },
    ]
  )


  # Ensure the IAM role has been created (and the policies have been attached)
  # before creating the auto-scaling group.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_full_access
  ]
}


resource "aws_launch_template" "eks_self_managed_nodes" {
  name_prefix = "${var.eks_cluster_name}-${local.node_group_name}"
  description = "Amazon EKS self-managed nodes"

  instance_type          = var.instance_type
  image_id               = data.aws_ami.selected_eks_optimized_ami.id
  key_name               = "eks-node-secrets-keypair"
  update_default_version = true

  vpc_security_group_ids = [aws_security_group.eks_node.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.eks_self_managed_node_group.arn
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", 
    {
       cluster_name = var.eks_cluster_name
       node_labels  = var.node_labels
    }
  ))

  tags = var.tags
}



resource "aws_security_group" "eks_node" {
    name        = "eks-worker-node"
    description = "Security group for all nodes in the cluster"
    vpc_id      = data.aws_vpc.selected.id

    tags = {
    Name                                    = "morningstar_eks_cluster_sg"
    "kubernetes.io/cluster/morningstar_eks"      = "owned"
  }
}

resource "aws_security_group_rule" "eks_node_sg_ingress" {
    type                     = "ingress"
    description              = "Allow node to communicate with each other"
    protocol                 = "-1"
    from_port                = 0
    to_port                  = 65535
    security_group_id        = aws_security_group.eks_node.id
    source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_node_to_all_egress" {
    type                     = "egress"
    description              = "Allow node to communicate with internet"
    protocol                 = "-1"
    from_port                = 0
    to_port                  = 65535
    security_group_id        = aws_security_group.eks_node.id
    cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_control_plane_sg_ingress" {
    type                     = "ingress"
    description              = "Allow pods to communicate with the cluster API Server"
    protocol                 = "tcp"
    from_port                = 443
    to_port                  = 443
    security_group_id        = data.aws_eks_cluster.selected.vpc_config[0].cluster_security_group_id
    source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_control_plane_egress_to_node_sg" {
    type                     = "egress"
    description              = "Allow the cluster control plane to communicate with worker Kubelet and pods"
    protocol                 = "tcp"
    from_port                = 1025
    to_port                  = 65535
    security_group_id        = data.aws_eks_cluster.selected.vpc_config[0].cluster_security_group_id
    source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_control_plane_egress_to_node_sg_on_443" {
    type                     = "egress"
    description              = "Allow the cluster control plane to communicate with pods running extension API servers on port 443"
    protocol                 = "tcp"
    from_port                = 443
    to_port                  = 443
    security_group_id        = data.aws_eks_cluster.selected.vpc_config[0].cluster_security_group_id
    source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "eks_node_sg_from_control_plane_ingress" {
    type                     = "ingress"
    description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    protocol                 = "tcp"
    from_port                = 1025
    to_port                  = 65535
    security_group_id        = aws_security_group.eks_node.id
    source_security_group_id = data.aws_eks_cluster.selected.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "eks_node_sg_from_control_plane_on_443_ingress" {
    type                     = "ingress"
    description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
    protocol                 = "tcp"
    from_port                = 443
    to_port                  = 443
    security_group_id        = aws_security_group.eks_node.id
    source_security_group_id = data.aws_eks_cluster.selected.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "sg_ingress_public_ssh" {
    security_group_id = aws_security_group.eks_node.id
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
}


locals {
  ami_block_device_mappings = {
    for bdm in data.aws_ami.selected_eks_optimized_ami.block_device_mappings : bdm.device_name => bdm
  }
  root_block_device_mapping = local.ami_block_device_mappings[data.aws_ami.selected_eks_optimized_ami.root_device_name]
}
