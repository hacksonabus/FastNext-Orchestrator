from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="FastNext Orchestrator API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with specific domain
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"project": "FastNext Orchestrator", "status": "Online"}

@app.get("/api/health")
def health_check():
    return {
        "status": "Healthy",
        "version": "1.0.0",
        "engine": "FastAPI",
        "orchestrator": "Kubernetes"
    }
