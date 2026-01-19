# Application Code

This directory contains the source code for the 3-tier application:

## Files

- **backend.py**: Flask-based REST API server
- **frontend.html**: Simple web interface
- **Dockerfile.backend**: Docker image definition for the backend
- **Dockerfile.frontend**: Docker image definition for the frontend
- **nginx.conf**: Nginx configuration for the frontend
- **requirements.txt**: Python dependencies for the backend

## Building Docker Images

Before deploying with Terraform, you need to build the Docker images locally:

```bash
# Build backend image
docker build -t k8s-backend:latest -f Dockerfile.backend .

# Build frontend image
docker build -t k8s-frontend:latest -f Dockerfile.frontend .

# Load images into Minikube (if not done automatically)
minikube image load k8s-backend:latest
minikube image load k8s-frontend:latest
```

## Application Architecture

- **Frontend (Port 80)**: Nginx serving static HTML
- **Backend (Port 8080)**: Flask API with database connectivity
- **Database (Port 5432)**: PostgreSQL with persistent storage

The application provides a simple interface to add and retrieve messages from the database, demonstrating the complete 3-tier architecture.