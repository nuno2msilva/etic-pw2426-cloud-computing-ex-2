# Secret stores sensitive database credentials (base64 encoded automatically)
resource "kubernetes_secret" "database" {
  metadata {
    name      = "${var.cluster_name}-database-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  data = {
    POSTGRES_USER     = var.database_user
    POSTGRES_PASSWORD = var.database_password
    POSTGRES_DB       = var.database_name
  }
}

# Service provides stable DNS name for database access within cluster
resource "kubernetes_service" "database" {
  metadata {
    name      = "${var.cluster_name}-database-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    selector = {
      app = "${var.cluster_name}-database"
    }
    port {
      name        = "postgresql"
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"  # Internal access only
  }
}

# StatefulSet ensures stable network identity and ordered deployment for database
resource "kubernetes_stateful_set" "database" {
  metadata {
    name      = "${var.cluster_name}-database"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    service_name = kubernetes_service.database.metadata[0].name
    replicas     = 1  # Single database instance - StatefulSets don't support HA out of the box
    
    selector {
      match_labels = {
        app       = "${var.cluster_name}-database"
        component = "database"
      }
    }
    
    template {
      metadata {
        labels = merge(local.common_labels, {
          app       = "${var.cluster_name}-database"
          component = "database"
        })
      }
      
      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"  # Lightweight PostgreSQL image
          
          port {
            name           = "postgresql"
            container_port = 5432
          }
          
          # Load all environment variables from secret
          env_from {
            secret_ref {
              name = kubernetes_secret.database.metadata[0].name
            }
          }
          
          # Mount persistent storage for database data
          volume_mount {
            name       = "database-storage"
            mount_path = "/var/lib/postgresql/data"
          }
          
          # Resource limits (optional but good practice)
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }
        }
        
        volume {
          name = "database-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.database.metadata[0].name
          }
        }
      }
    }
  }
}
