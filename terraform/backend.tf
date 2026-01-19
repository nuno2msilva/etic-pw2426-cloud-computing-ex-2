# ConfigMap stores non-sensitive backend configuration
resource "kubernetes_config_map" "backend" {
  metadata {
    name      = "${var.cluster_name}-backend-config"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  data = {
    DB_HOST = kubernetes_service.database.metadata[0].name
    DB_PORT = "5432"
    DB_NAME = var.database_name
    DB_USER = var.database_user
  }
}

# Service provides stable DNS name for backend access within cluster
resource "kubernetes_service" "backend" {
  metadata {
    name      = "${var.cluster_name}-backend-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    selector = {
      app       = "${var.cluster_name}-backend"
      component = "api"
    }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"  # Internal access only
  }
}

# Deployment manages replicated Flask API pods
resource "kubernetes_deployment" "backend" {
  depends_on = [kubernetes_stateful_set.database]
  
  metadata {
    name      = "${var.cluster_name}-backend"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    replicas = local.config.backend_replicas
    
    selector {
      match_labels = {
        app       = "${var.cluster_name}-backend"
        component = "api"
      }
    }
    
    template {
      metadata {
        labels = merge(local.common_labels, {
          app       = "${var.cluster_name}-backend"
          component = "api"
        })
      }
      
      spec {
        # Wait for database to be ready before starting backend
        init_container {
          name  = "wait-for-database"
          image = "busybox:1.36"
          command = [
            "sh", "-c",
            "until nc -z ${kubernetes_service.database.metadata[0].name} 5432; do echo 'Waiting for database...'; sleep 2; done; echo 'Database ready!'"
          ]
        }
        
        container {
          name              = "backend"
          image             = "k8s-backend:latest"
          image_pull_policy = "Never"  # Use local image from minikube
          
          port {
            name           = "http"
            container_port = 8080
          }
          
          # Load configuration from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend.metadata[0].name
            }
          }
          
          # Sensitive database password from Secret
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          
          # Optional: Pod metadata for debugging/monitoring
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          
          # Resource limits (good practice)
          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi" 
              cpu    = "200m"
            }
          }
        }
      }
    }
  }
}
