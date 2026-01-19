resource "kubernetes_persistent_volume_claim" "database" {
  metadata {
    name      = "${var.cluster_name}-database-pvc"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]  # Single node read-write access
    resources {
      requests = {
        storage = local.config.storage_size  # Different sizes for dev/prod
      }
    }
  }
}
