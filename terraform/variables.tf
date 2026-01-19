# Minikube cluster name (used as context in kubeconfig)
variable "cluster_name" {
  description = "Name of the Kubernetes cluster and prefix for all resources"
  type        = string
  default     = "terraform-cluster"
  
  validation {
    condition     = length(var.cluster_name) > 3 && can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must be longer than 3 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

# PostgreSQL authentication credentials
variable "database_user" {
  description = "PostgreSQL database username"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "PostgreSQL database password - change this in production!"
  type        = string
  default     = "secretpassword"
  sensitive   = true # Masks value in terraform output
}

variable "database_name" {
  description = "Name of the PostgreSQL database to create"
  type        = string
  default     = "k8s_app"
}


locals {
  environment = terraform.workspace
  env_config = {
    dev = {
      namespace         = "dev"
      frontend_replicas = 2      # ← SCALE: Number of frontend pods in dev environment
      backend_replicas  = 2      # ← SCALE: Number of backend pods in dev environment  
      storage_size      = "1Gi"  # ← SCALE: Database storage size for dev
      nodes             = 2      # ← SCALE: Number of Kubernetes nodes for dev
    }
    prod = {
      namespace         = "prod" 
      frontend_replicas = 2      # ← SCALE: Number of frontend pods in prod environment
      backend_replicas  = 3      # ← SCALE: Number of backend pods in prod environment
      storage_size      = "5Gi"  # ← SCALE: Database storage size for prod
      nodes             = 3      # ← SCALE: Number of Kubernetes nodes for prod
    }
  }
  
  # Current environment configuration
  config = local.env_config[local.environment]
  
  # Common labels applied to all resources
  common_labels = {
    "app.kubernetes.io/name"       = var.cluster_name
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "3tier-web-app"
    "environment"                  = local.environment
  }
}
