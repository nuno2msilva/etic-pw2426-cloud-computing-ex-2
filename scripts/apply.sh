#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="terraform-cluster"
ENV="${1:-dev}"

[[ "$ENV" != "dev" && "$ENV" != "prod" ]] && { echo "Usage: $0 [dev|prod]"; exit 1; }

# Get number of nodes from Terraform variables (the single source of truth)
cd "$SCRIPT_DIR/../terraform"
terraform init -upgrade &>/dev/null || true
terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV" &>/dev/null || true
NODES=$(terraform console <<< "local.config.nodes" 2>/dev/null | tr -d '"')
NODES=${NODES:-2}  # Fallback if terraform fails

echo "Setting up $ENV environment with $NODES nodes..."

# Create cluster (simple version)
if ! minikube status --profile "$CLUSTER_NAME" &>/dev/null; then
    minikube start --profile="$CLUSTER_NAME" --nodes="$NODES"
fi

# Enable basic addons
minikube addons enable ingress --profile "$CLUSTER_NAME"

# Wait for ingress to be ready
sleep 30

# Build and load images (simplified)
cd "$SCRIPT_DIR/../app"
docker build -f Dockerfile.backend -t k8s-backend:latest .
docker build -f Dockerfile.frontend -t k8s-frontend:latest .
minikube image load k8s-backend:latest --profile "$CLUSTER_NAME"
minikube image load k8s-frontend:latest --profile "$CLUSTER_NAME"

# Deploy with Terraform
cd "$SCRIPT_DIR/../terraform"
terraform init
terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV"
terraform apply -auto-approve

# Start port forwarding
pkill -f "port-forward.*ingress-nginx" 2>/dev/null || true
nohup kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8443:443 >/dev/null 2>&1 &

echo ""
echo "=== $ENV deployed ==="
kubectl get pods -n "$ENV"
echo ""
[[ "$ENV" = "prod" ]] && echo "Access: https://localhost:8443/" || echo "Access: https://localhost:8443/dev/"
