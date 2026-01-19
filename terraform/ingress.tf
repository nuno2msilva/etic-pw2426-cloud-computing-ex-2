resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "${var.cluster_name}-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
    
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"   # Strips path prefix
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"  # Force HTTPS
    }
  }
  
  spec {
    ingress_class_name = "nginx"
    
    # HTTPS certificate
    tls {
      hosts       = ["localhost"]
      secret_name = kubernetes_secret.tls.metadata[0].name
    }
    
    # Production environment - root paths (/)
    dynamic "rule" {
      for_each = local.environment == "prod" ? [1] : []
      content {
        http {
          # Frontend: / -> frontend service
          path {
            path      = "/()(.*)"
            path_type = "ImplementationSpecific"
            backend {
              service {
                name = kubernetes_service.frontend.metadata[0].name
                port {
                  number = 80
                }
              }
            }
          }
          
          # Backend API: /api -> backend service
          path {
            path      = "/api(/|$)(.*)"
            path_type = "ImplementationSpecific"
            backend {
              service {
                name = kubernetes_service.backend.metadata[0].name
                port {
                  number = 8080
                }
              }
            }
          }
        }
      }
    }
    
    # Development environment - /dev paths
    dynamic "rule" {
      for_each = local.environment == "dev" ? [1] : []
      content {
        http {
          # Frontend: /dev -> frontend service
          path {
            path      = "/dev(/|$)(.*)"
            path_type = "ImplementationSpecific"
            backend {
              service {
                name = kubernetes_service.frontend.metadata[0].name
                port {
                  number = 80
                }
              }
            }
          }
          
          # Backend API: /dev/api -> backend service
          path {
            path      = "/dev/api(/|$)(.*)"
            path_type = "ImplementationSpecific"
            backend {
              service {
                name = kubernetes_service.backend.metadata[0].name
                port {
                  number = 8080
                }
              }
            }
          }
        }
      }
    }
  }
}
