# FastNext Orchestrator
FastNext Orchestrator is a full-stack proof-of-concept (POC) that deploys a FastAPI backend and a Next.js frontend onto a single-node Kubernetes (K3s) cluster running on Debian 12.9.

## System Architecture
Frontend: Next.js 14+ (App Router) running on Port 30002 (NodePort).

Backend: FastAPI (Python 3.11) running on Port 30001 (NodePort).

Orchestration: K3s (Lightweight Kubernetes).

Container Engine: Docker (for builds) and Containerd (K3s runtime).

## Quick Start (Automated Deployment)
We provide a lifecycle manager script that handles system dependencies, user permissions, container builds, and Kubernetes orchestration.

### 1. Prerequisites
A fresh install of Debian 12.9.

Root access (to install sudo and configure groups).

### 2. Execution
Download or create orchestrator_manager.sh, then run:

Bash
```
# Set your username in the script first!
nano orchestrator_manager.sh
# Update TARGET_USER="your_username"

chmod +x orchestrator_manager.sh
sudo ./orchestrator_manager.sh
```
