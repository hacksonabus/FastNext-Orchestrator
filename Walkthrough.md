# FastNext Orchestrator: Full-Stack K8s POC

This guide transforms a fresh Ubuntu server into a container-orchestrated environment using **FastAPI**, **Next.js**, **Docker**, and **K3s**.

## Step 1: Environment Setup

Run these commands to install the necessary engines on your Ubuntu server.

```bash
# 1. Update System
sudo apt update && sudo apt upgrade -y

# 2. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER
# NOTE: Log out and back in after this step to refresh group permissions.

# 3. Install Node.js (via NVM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20

# 4. Install K3s (Kubernetes)
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
source ~/.bashrc

# 5. Create Project Structure
mkdir -p ~/FastNext-Orchestrator/backend ~/FastNext-Orchestrator/k8s

```

---

## Step 2: The Backend (FastAPI)

Navigate to `~/FastNext-Orchestrator/backend` and create the following three files.

### 1. `requirements.txt`

```text
fastapi==0.109.0
uvicorn==0.27.0

```

### 2. `main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="FastNext API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
def health():
    return {"status": "Online", "orchestrator": "Kubernetes", "message": "Backend is reachable!"}

```

### 3. `Dockerfile`

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

```

---

## Step 3: The Frontend (Next.js)

### 1. Initialize Project

Run this from `~/FastNext-Orchestrator`:

```bash
npx create-next-app@latest frontend --typescript --tailwind --eslint --src-dir --app
# Accept all default "Yes" prompts.

```

### 2. Update `frontend/src/app/page.tsx`

Replace the content with this code:

```tsx
"use client";
import { useEffect, useState } from 'react';

export default function Home() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    const ip = window.location.hostname;
    fetch(`http://${ip}:30001/api/health`)
      .then(res => res.json())
      .then(setData)
      .catch(() => setData({status: "Offline - Check Firewall"}));
  }, []);

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-900 text-white font-sans">
      <div className="p-10 bg-slate-800 rounded-2xl border border-blue-500 shadow-2xl text-center">
        <h1 className="text-3xl font-bold mb-4 bg-gradient-to-r from-blue-400 to-cyan-300 bg-clip-text text-transparent">
          FastNext Orchestrator
        </h1>
        <div className="p-4 bg-black/50 rounded-lg">
          <p className="font-mono text-green-400">
            Backend Status: {data ? JSON.stringify(data.status) : "Connecting..."}
          </p>
        </div>
      </div>
    </main>
  );
}

```

### 3. Create `frontend/Dockerfile`

Create this inside `~/FastNext-Orchestrator/frontend/`:

```dockerfile
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

```

---

## Step 4: Build & Deploy

### 1. Build & Import Images

From `~/FastNext-Orchestrator`:

```bash
# Build
docker build -t fastnext-backend:v1 ./backend
docker build -t fastnext-frontend:v1 ./frontend

# Import into K3s (This makes them available to Kubernetes)
docker save fastnext-backend:v1 | sudo k3s ctr images import -
docker save fastnext-frontend:v1 | sudo k3s ctr images import -

```

### 2. Create `k8s/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fn-backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: fastnext-backend:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: fn-backend-service
spec:
  type: NodePort
  selector:
    app: backend
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30001
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fn-frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: fastnext-frontend:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: fn-frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30002

```

### 3. Execution

```bash
# Cleanup previous attempts
kubectl delete svc fn-backend-service fn-frontend-service --ignore-not-found

# Deploy
kubectl apply -f k8s/deployment.yaml

# Open Server Firewall
sudo ufw allow 30001/tcp
sudo ufw allow 30002/tcp

```

---

## Step 5: Verification

1. **Check Pods:** `kubectl get pods` (Wait until Status is `Running`)
2. **Access App:** Go to `http://<YOUR_SERVER_IP>:30002` in your browser.

---

### `.gitignore` (Root Directory)

```text
node_modules/
.next/
__pycache__/
*.pyc
.env
venv/

```

**Would you like me to help you set up an Ingress Controller next so you can access this via a domain name (HTTP/HTTPS) instead of port 30002?**
