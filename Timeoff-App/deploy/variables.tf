variable "prefix" {
  default = "intrv"
}

variable "project" {
  default = "time-off-mgmt-app"
}

variable "contact" {
  default = "sandeeppillai03@gmail.com"
}

# Database #
variable "db_username" {
  description = "Username for the RDS MySQL instance"
}

variable "db_password" {
  description = "Password for the RDS MySQL instance"
}

# App image in ECR #
variable "ecr_image_app" {
  description = "ECR Image for APP"
  default     = "213469863961.dkr.ecr.us-east-1.amazonaws.com/timeoff-management-app-interview:latest"
}

# Bastion

variable "bastion_key_name" {
  default = "timeoff-mgmt-app-bastion"
}

# Custom Domain #

variable "dns_zone_name" {
  description = "Domain name"
  default     = "devopslearninglab.com"
}

variable "subdomain" {
  description = "Subdomain per environment"
  type        = map(string)
  default = {
    production = "timeoffmgmt"
    staging    = "timeoffmgmt.staging"
    dev        = "timeoffmgmt.dev"
  }
}
