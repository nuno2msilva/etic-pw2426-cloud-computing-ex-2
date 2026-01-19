resource "kubernetes_namespace" "app" {
  metadata {
    name   = local.config.namespace  # "dev" or "prod" based on workspace
    labels = local.common_labels
  }
}
