#!/bin/bash

# =================================================================
# FastNext Orchestrator - Debian 12.9 Full Lifecycle Manager
# =================================================================

# 1. CONFIGURATION
TARGET_USER="YOUR_USERNAME" # <--- CHANGE THIS
PROJECT_ROOT="/home/$TARGET_USER/FastNext-Orchestrator"
KUBE_CONFIG="/etc/rancher/k3s/k3s.yaml"

if [ "$EUID" -ne 0 ]; then 
  echo "Error: Please run as root"
  exit 1
fi

# 2. CLEANUP MODULE
cleanup_previous() {
    echo "Wiping previous installation..."
    if [ -f "$KUBE_CONFIG" ]; then
        export KUBECONFIG=$KUBE_CONFIG
        kubectl delete -f "$PROJECT_ROOT/k8s/deployment.yaml" --ignore-not-found 2>/dev/null
    fi
    docker rmi fastnext-backend:v1 fastnext-frontend:v1 --force 2>/dev/null
    rm -rf "$PROJECT_ROOT"
    echo "System cleaned."
}

read -p "Do you want to remove previous versions? (y/n): " confirm
[[ $confirm == [yY] ]] && cleanup_previous

# 3. DIRECTORY & GIT SETUP
echo "Creating directory structure..."
mkdir -p "$PROJECT_ROOT/backend" "$PROJECT_ROOT/frontend" "$PROJECT_ROOT/k8s"

cat <<EOF > "$PROJECT_ROOT/.gitignore"
node_modules/
.next/
__pycache__/
.env
*.log
.kube/
EOF

# 4. SYSTEM INSTALLATION
echo "Installing engines..."
apt update && apt install -y sudo curl wget git iptables build-essential ufw
if ! [ -x "$(command -v docker)" ]; then curl -fsSL https://get.docker.com | sh; fi
if ! [ -x "$(command -v node)" ]; then curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt install -y nodejs; fi
if ! [ -x "$(command -v k3s)" ]; then curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address 0.0.0.0" sh -; fi

usermod -aG sudo,docker $TARGET_USER
chmod 644 $KUBE_CONFIG
export KUBECONFIG=$KUBE_CONFIG

# 5. SOURCE CODE GENERATION
echo "Writing Backend (FastAPI)..."
cat <<EOF > "$PROJECT_ROOT/backend/main.py"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
@app.get("/api/health")
def health(): return {"status": "Online", "browsable": True}
EOF

echo -e "fastapi==0.109.0\nuvicorn==0.27.0" > "$PROJECT_ROOT/backend/requirements.txt"

cat <<EOF > "$PROJECT_ROOT/backend/Dockerfile"
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

echo "Initializing Frontend (Next.js)..."
cd "$PROJECT_ROOT"
npx create-next-app@latest frontend --typescript --tailwind --eslint --src-dir --app --yes

cat <<EOF > "$PROJECT_ROOT/frontend/src/app/page.tsx"
"use client";
import { useEffect, useState } from 'react';
export default function Home() {
  const [status, setStatus] = useState('Connecting...');
  useEffect(() => {
    fetch(\`http://\${window.location.hostname}:30001/api/health\`)
      .then(res => res.json()).then(data => setStatus(data.status))
      .catch(() => setStatus('Offline'));
  }, []);
  return (
    <main className="flex min-h-screen items-center justify-center bg-zinc-950 text-white">
      <div className="p-12 bg-zinc-900 border border-blue-500/30 rounded-3xl shadow-2xl text-center">
        <h1 className="text-3xl font-bold text-blue-500 mb-2 italic">FastNext</h1>
        <p className="font-mono text-green-400">API: {status}</p>
      </div>
    </main>
  );
}
EOF

cat <<EOF > "$PROJECT_ROOT/frontend/Dockerfile"
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["npm", "start"]
EOF

# 6. K8S MANIFEST
cat <<EOF > "$PROJECT_ROOT/k8s/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fn-backend
spec:
  replicas: 1
  selector: {matchLabels: {app: backend}}
  template:
    metadata: {labels: {app: backend}}
    spec:
      containers:
      - name: backend
        image: fastnext-backend:v1
        imagePullPolicy: Never
        ports: [{containerPort: 8000}]
---
apiVersion: v1
kind: Service
metadata: {name: fn-backend-service}
spec:
  type: NodePort
  selector: {app: backend}
  ports: [{port: 8000, targetPort: 8000, nodePort: 30001}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: fn-frontend}
spec:
  replicas: 1
  selector: {matchLabels: {app: frontend}}
  template:
    metadata: {labels: {app: frontend}}
    spec:
      containers:
      - name: frontend
        image: fastnext-frontend:v1
        imagePullPolicy: Never
        ports: [{containerPort: 3000}]
---
apiVersion: v1
kind: Service
metadata: {name: fn-frontend-service}
spec:
  type: NodePort
  selector: {app: frontend}
  ports: [{port: 3000, targetPort: 3000, nodePort: 30002}]
EOF

# 7. BUILD & ORCHESTRATE
echo "Building & Deploying..."
docker build -t fastnext-backend:v1 "$PROJECT_ROOT/backend"
docker build -t fastnext-frontend:v1 "$PROJECT_ROOT/frontend"
docker save fastnext-backend:v1 | k3s ctr images import -
docker save fastnext-frontend:v1 | k3s ctr images import -

kubectl taint nodes --all node-role.kubernetes.io/master- || true
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
kubectl apply -f "$PROJECT_ROOT/k8s/deployment.yaml"

chown -R $TARGET_USER:$TARGET_USER "$PROJECT_ROOT"

# 8. HEALTH CHECK
echo "Verifying Network Access..."
NODE_IP=$(hostname -I | awk '{print $1}')
for i in {1..15}; do
    if curl -s -o /dev/null "http://$NODE_IP:30001/api/health"; then
        echo "DEPLOYMENT SUCCESSFUL!"
        echo "UI: http://$NODE_IP:30002"
        echo "Streaming Logs..."
        kubectl logs -f -l 'app in (backend, frontend)' --prefix
        exit 0
    fi
    echo "Waiting for pods... ($i/15)"
    sleep 10
done
