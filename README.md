# FastNext Orchestrator 🚀

**FastNext Orchestrator** is a production-ready Proof of Concept (POC) designed to deploy a modern full-stack application on Kubernetes in minutes. It bridges a high-performance Python backend with a reactive TypeScript frontend.

## Tech Stack
- **Backend:** Python, FastAPI
- **Frontend:** Next.js 14+, TypeScript, Tailwind CSS
- **Containerization:** Docker
- **Orchestration:** Kubernetes (K3s optimized)

- FastNext-Orchestrator/
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/app/page.tsx
│   ├── Dockerfile
│   └── ... (Next.js boilerplate)
├── k8s/
│   └── deployment.yaml
├── .gitignore
└── README.md

## Quick Start (Ubuntu Server)

### 1. Initialize Environment
```bash
# Install Docker & K3s
curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh && sudo sh get-docker.sh
curl -sfL [https://get.k3s.io](https://get.k3s.io) | sh -

# Configure Permissions
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
