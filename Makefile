.PHONY: run install start stop dev prod test pods destroy clear help

run: install start

install:
	@./scripts/init.sh

start: dev prod
	@echo ""
	@echo "=== Both environments running ==="
	@echo "Prod: https://localhost:8443/"
	@echo "Dev:  https://localhost:8443/dev/"

stop:
	@-pkill -f "port-forward.*ingress-nginx" 2>/dev/null || true
	@echo "Server stopped"

dev:
	@./scripts/apply.sh dev

prod:
	@./scripts/apply.sh prod

test:
	@./scripts/test.sh

pods:
	@echo "=== Dev ===" && kubectl get pods -n dev -o wide 2>/dev/null || echo "No dev pods"
	@echo ""
	@echo "=== Prod ===" && kubectl get pods -n prod -o wide 2>/dev/null || echo "No prod pods"

destroy:
	@./scripts/destroy.sh

clear:
	@-pkill -f "port-forward.*ingress-nginx" 2>/dev/null || true
	@./scripts/destroy.sh 2>/dev/null || true
	@minikube delete --profile terraform-cluster 2>/dev/null || true
	@rm -rf terraform/.terraform terraform/.terraform.lock.hcl terraform/terraform.tfstate* terraform/terraform.tfstate.d
	@echo "All cleared"

help:
	@echo "run     - Install and start everything"
	@echo "install - Initialize Terraform"
	@echo "start   - Deploy dev + prod environments"
	@echo "stop    - Stop port forwarding (server offline)"
	@echo "dev     - Deploy dev only (2 nodes)"
	@echo "prod    - Deploy prod only (3 nodes)"
	@echo "test    - Test both environments"
	@echo "pods    - Show all pods"
	@echo "destroy - Destroy Terraform resources"
	@echo "clear   - Full reset (cluster + state)"
