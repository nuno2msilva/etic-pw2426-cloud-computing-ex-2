#!/bin/bash
set -e

CLUSTER_NAME="terraform-cluster"
ENV="${1:-all}"
cd "$(dirname "$0")/../terraform"

terraform init -upgrade 2>/dev/null

if [ "$ENV" = "all" ]; then
    for ws in dev prod; do
        terraform workspace select "$ws" 2>/dev/null && terraform destroy -auto-approve || true
    done
    terraform workspace select default 2>/dev/null || true
else
    terraform workspace select "$ENV" 2>/dev/null && terraform destroy -auto-approve
fi

echo "Terraform resources destroyed"
