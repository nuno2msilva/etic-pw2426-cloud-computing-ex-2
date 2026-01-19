# Practical Exercise – Kubernetes Infrastructure with Terraform

Recreated the project from the previous exercise, but this time use Terraform and everything I've learned from current week.

## How this exercise relates to the previous one:
This exercise relates to the previous one since it implements the same 3-tier web application architecture (frontend, backend, database) on Kubernetes, but using Terraform for infrastructure management instead of manual YAML files.

## What I reused and what's different:

**What I kept the same:**
- Same Flask backend and Nginx frontend code
- Same Docker images and Dockerfiles  
- Same PostgreSQL database
- Same Kubernetes resources (Deployments, Services, Ingress, etc.)

**What changed:**
- Instead of `kubectl apply -f` commands → now use `terraform apply`
- Instead of single environment → now have dev and prod environments
- Instead of manual setup → now have automated scripts
- Terraform tracks what's deployed, YAML files didn't

## What the app does:
It's a simple 3-tier web application where:
- **Frontend** (Nginx) serves the web page
- **Backend** (Flask) handles API requests  
- **Database** (PostgreSQL) stores data

You access it at https://localhost:8443/ (prod) or https://localhost:8443/dev/ (dev).

## How to use this project:

**Quick start:** Just run `make run` and it sets up everything for you.

**What happens:**
1. Initializes Terraform 
2. Creates a Minikube cluster
3. Deploys dev environment (2 nodes, 2 replicas each)  
4. Deploys prod environment (3 nodes, more replicas)
5. You can access the apps at the URLs above

**Useful commands:**
- `make run` - Initialize and deploy everything (complete setup)
- `make start` - Deploy everything (if already initialized)
- `make test` - Check if it's working
- `make pods` - See what's running
- `make dev` - Deploy just dev environment
- `make prod` - Deploy just prod environment
- `make stop` - Stop the server access
- `make destroy` - Remove everything but keep cluster
- `make clear` - Delete everything and start fresh

## Project files:
```
├── terraform/          # All the infrastructure code
├── scripts/            # Automation scripts  
├── app/               # The actual web application code
└── Makefile           # Easy commands
```

## How to destroy the environment:

**Option 1: Just remove the apps (recommended)**
```bash
make destroy  
```
This removes the web apps but keeps the cluster running.

**Option 2: Remove everything (nuclear option)**
```bash
make clear
```
This deletes everything - the apps, the cluster, all files. You'll need to start fresh.

**Option 3: Remove specific parts**
```bash
./scripts/destroy.sh dev      # Remove just dev
./scripts/destroy.sh prod     # Remove just prod  
./scripts/destroy.sh all      # Remove both
```

## Known limitations:

1. **Only works locally** - Uses Minikube, not a real cloud
2. **Browser security warnings** - Uses self-signed certificates (just click "proceed to localhost")
3. **Data gets deleted** - Database data disappears when you run `make clear`
4. **Need to keep terminal open** - Port forwarding requires the terminal to stay running

## If something breaks:

**Can't access the website?**
```bash
make stop
make start
```

**Pods not starting?**
```bash
make pods  # See what's running
kubectl logs -n dev <pod-name>  # Check errors
```

**Everything is broken?**
```bash
make clear  # Delete everything
make start  # Start fresh
```

---

*This project shows how to use Terraform with Kubernetes to deploy the same app to multiple environments automatically.*

