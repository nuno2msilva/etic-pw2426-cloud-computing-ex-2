# Service provides stable DNS name for frontend access within cluster
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "${var.cluster_name}-frontend-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    selector = {
      app       = "${var.cluster_name}-frontend"
      component = "web"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"  # Internal access only
  }
}

# Deployment manages replicated Nginx frontend pods
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "${var.cluster_name}-frontend"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    replicas = local.config.frontend_replicas
    
    selector {
      match_labels = {
        app       = "${var.cluster_name}-frontend"
        component = "web"
      }
    }
    
    template {
      metadata {
        labels = merge(local.common_labels, {
          app       = "${var.cluster_name}-frontend"
          component = "web"
        })
      }
      
      spec {
        container {
          name              = "frontend"
          image             = "k8s-frontend:latest"
          image_pull_policy = "Never"  # Use local image from minikube
          
          port {
            name           = "http"
            container_port = 80
          }
          
          # Resource limits (lightweight for static content)
          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }
}
