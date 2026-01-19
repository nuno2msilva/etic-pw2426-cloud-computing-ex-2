terraform {
  required_version = ">= 1.0"
  
  required_providers {
    # Kubernetes provider for managing K8s resources
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    
    # TLS provider for generating self-signed certificates
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Configure Kubernetes provider to use minikube cluster
provider "kubernetes" {
  config_path    = "~/.kube/config"    # Path to kubeconfig file
  config_context = var.cluster_name    # Minikube cluster context name
}
