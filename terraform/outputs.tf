# Cluster name for reference
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

# Current environment (dev or prod)
output "environment" {
  description = "Current Terraform workspace (dev/prod)"
  value       = local.environment
}

# Kubernetes namespace created for this environment
output "namespace" {
  description = "Kubernetes namespace for this environment"
  value       = kubernetes_namespace.app.metadata[0].name
}

# Application configuration summary
output "app_config" {
  description = "Application configuration summary"
  value = {
    frontend_replicas = local.config.frontend_replicas
    backend_replicas  = local.config.backend_replicas
    storage_size      = local.config.storage_size
  }
}

# URL to access the application (different paths for dev and prod)
output "app_url" {
  description = "URL to access the application"
  value       = local.environment == "prod" ? "https://localhost:8443/" : "https://localhost:8443/dev/"
}

# Useful commands for this environment
output "useful_commands" {
  description = "Helpful kubectl commands for this environment"
  value = {
    get_pods     = "kubectl get pods -n ${kubernetes_namespace.app.metadata[0].name}"
    get_services = "kubectl get services -n ${kubernetes_namespace.app.metadata[0].name}"
    logs_backend = "kubectl logs -n ${kubernetes_namespace.app.metadata[0].name} -l app=${var.cluster_name}-backend"
    port_forward = "kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8443:443"
  }
}
