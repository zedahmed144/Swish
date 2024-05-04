# Required input variables

variable "eks_cluster_name" {
  type        = string
  description = "(Required) The name of the Amazon EKS cluster."
  
}

variable "instance_type" {
  type        = string
  description = "(Required) The EC2 instance type to use for the worker nodes."
  
}

variable "desired_capacity" {
  type        = number
  description = "(Required) The desired number of nodes to create in the node group."
  
}

variable "min_size" {
  type        = number
  description = "(Required) The minimum number of nodes to create in the node group."
  
}

variable "max_size" {
  type        = number
  description = "(Required) The maximum number of nodes to create in the node group."
  
}

variable "name" {
  type        = string
  description = "(Optional) The name to be used for the self-managed node group. By default, the module will generate a unique name."
  default     = ""
}

variable "name_prefix" {
  type        = string
  description = "(Optional) Creates a unique name beginning with the specified prefix. Conflicts with `name`."
  default     = "node-group"
}

variable "tags" {
  type        = map(any)
  description = "(Optional) Tags to apply to all tag-able resources."
  default     = {}
}

variable "node_labels" {
  type        = map(any)
  description = "(Optional) Kubernetes labels to apply to all nodes in the node group."
  default     = {}
}


variable "security_group_ids" {
  type        = list(string)
  description = "(Optional) A list of security group IDs to associate with the worker nodes. The module automatically associates the EKS cluster security group with the nodes."
  default     = []
}





# Local variables

resource "random_id" "name_suffix" {
  byte_length = 8
}

locals {
  node_group_name = coalesce(var.name, "${var.name_prefix}-${random_id.name_suffix.hex}")
}
