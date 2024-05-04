
# Amazon Elastic Kubernetes Service (Amazon EKS)
is a managed service that you can use to run Kubernetes on AWS without needing to install, operate, and maintain your own Kubernetes control plane or nodes. Is integrated with many AWS services to provide scalability and security for your applications, including the following capabilities:
- Amazon ECR for container images
- Elastic Load Balancing for load distribution
- IAM for authentication
- Amazon VPC for isolation

**Self-managed Linux nodes**
- Advantages of the EKS managed in comparison to self-managed node groups: we don’t need to separately provision or register the Amazon EC2 instances that provide compute capacity to run your Kubernetes applications. You can create, update, or terminate nodes for your cluster with a single operation. 
- Disadvantages of the EKS managed nodes: 
  - AMI versions aren’t up-to-date for managed worker groups (not the latest version).
  - You cannot roll back a node group to an earlier Kubernetes version or AMI version.
  - Not support for mixed instances! Only spot or demand instance. 
  - Can not run containers that require Windows. 


**Prerequisites**
- Configured an AWS CLI, have installed kubectl and Terraform on local machine.
- Configured a User and Assumed Role with the right set of permissions.



**VPC and EKS Terraform resources will be created**

[aws_eks_cluster]                                                   
[aws_iam_role_cluster]                                                    
[aws_iam_role_policy_attachment__AmazonEKSClusterPolicy]                  
[aws_iam_role_policy_attachment_AmazonEKSVPCResourceController]      
[aws_vpc_centos_vpc]
[aws_subnet_private[0]]
[aws_subnet_private[1]]
[aws_subnet_private[2]]
[aws_subnet_public[0]]
[aws_subnet_public[1]]
[aws_subnet_public[2]]
[aws_internet_gateway]                                                    
[aws_nat_gateway]                                          
[aws_eip]                                                                 
[aws_route_private]                                                       
[aws_route_public]
[aws_route_table_private]
[aws_route_tablepublic]
[aws_route_table_association_private]
[aws_route_table_association_private]
[aws_route_table_association_private]
[aws_route_table_association_public]
[aws_route_table_association_public]
[aws_route_table_association_public]


**Self-managed Linux node group Terraform resources will be created**

```terraform
module "eks_self_managed_node_group" {
  
  eks_cluster_name = "centos_eks"
  instance_type    = "t3.medium"
  desired_capacity = 2
  min_size         = 2
  max_size         = 4
    
}
```
[aws_autoscaling_group]
[aws_launch_template] 
[aws_iam_instance_profile]                                                
[aws_iam_role]                                                            
[aws_iam_role_policy_attachment]                                          
[aws_ami]                                                                 
[aws_ec2_instance_type] 
[aws_auth-config-map]
[aws_security_group]                                                      
[aws_security_group_rule]                                                     

Outputs

- `name` - The full name of the self-managed node group.
- `role_arn` - The ARN of the node group IAM role.
- `ami_id` - The ID of the selected Amazon EKS optimized AMI.
- `ami_name` - The name of the selected Amazon EKS optimized AMI.
- `ami_description` - The description of the selected Amazon EKS optimized AMI.
- `ami_creation_date` - The creation date of the selected Amazon EKS optimized AMI.

**NGINX Ingress Controller will be installed** 

**ExternalTrafficPolicy option will be patched from Local to Cluster (to ensure nodes are marked as healthy)** 


# Set up and initialise your Terraform workspace

# Clone the source code repository to your local machine and navigate to the directory 

```bash
git clone git@github.com:312-bc/devops-tools-22b-centos.git
cd devops-tools-22b-centos/Terraform/vpc-eks-self-managed-node-group
```

**Makefile is used to automate the deployment of the code**

# Step 1: Review AWS VPC and EKS resources to be created

```bash
make vpc-eks-init-plan 
```

# Step 2: Create all the necessary AWS VPC and EKS resources

```bash
make vpc-eks-apply
```

# Step 3: Review Self-managed nodes resources to be created

```bash
make worker-nodes-init-plan
```

# Step 4: Create all the necessary Self-managed nodes resources:
        This step will also:
           Configure kubectl, so that you can connect to an Amazon EKS cluster
           Install and validate Ingress NGINX 

```bash
make worker-nodes-apply
```

# Step 5: Delete all created self-managed nodes resources

```bash
make worker-nodes-destroy
```

# Step 6: Delete all created AWS VPC and EKS resources

```bash
make vpc-eks-destroy
```

**Additional automation opportunities**
- We can use S3 as the backend for storing .tfstate file. This prevents you from having to recreate your entire cluster if you were to ever lose access to your state file.
- We can use locking of state file, prevent concurrent operations on your resources.

**References links:** 
1. Amazon EKS cluster https://docs.aws.amazon.com/eks/latest/userguide/clusters.html
2. Launching self-managed nodes https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
3. Terraform documentation https://registry.terraform.io
4. Ingress-NGINX controller https://kubernetes.github.io/ingress-nginx/deploy/#aws
5. Update the pec.externalTrafficPolicy option to Cluster https://aws.amazon.com/premiumsupport/knowledge-center/eks-unhealthy-worker-node-nginx/#Set_the_policy_option
