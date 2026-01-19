# RSA private key for TLS certificate
resource "tls_private_key" "app" {
  algorithm = "RSA"
  rsa_bits  = 2048  # Standard key size for web certificates
}

# Self-signed certificate for HTTPS (valid 1 year)
resource "tls_self_signed_cert" "app" {
  private_key_pem = tls_private_key.app.private_key_pem
  
  subject {
    common_name  = "localhost"
    organization = "Terraform K8s Learning"
  }
  
  dns_names    = ["localhost", "*.localhost"]
  ip_addresses = ["127.0.0.1"]
  
  validity_period_hours = 8760  # 1 year
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature", 
    "server_auth",
  ]
}

# Kubernetes secret stores TLS cert for ingress to use
resource "kubernetes_secret" "tls" {
  metadata {
    name      = "${var.cluster_name}-tls"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = local.common_labels
  }
  
  type = "kubernetes.io/tls"
  
  data = {
    "tls.crt" = tls_self_signed_cert.app.cert_pem
    "tls.key" = tls_private_key.app.private_key_pem
  }
}
