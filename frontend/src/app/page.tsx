"use client";
import { useEffect, useState } from 'react';

export default function Home() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    const ip = window.location.hostname;
    fetch(`http://${ip}:30001/api/health`)
      .then(res => res.json())
      .then(setData)
      .catch(err => console.error("Connectivity Error:", err));
  }, []);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-slate-900 text-white p-6">
      <div className="max-w-xl w-full p-10 bg-slate-800 rounded-3xl shadow-2xl border border-blue-500/30">
        <h1 className="text-4xl font-extrabold tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-cyan-300 mb-2">
          FastNext Orchestrator
        </h1>
        <p className="text-slate-400 mb-8">Full-stack Kubernetes POC Template</p>
        
        <div className="space-y-4">
          <div className="p-5 bg-black/40 rounded-xl border border-slate-700">
            <p className="text-xs uppercase tracking-widest text-slate-500 font-bold mb-2">System Status</p>
            <div className="flex items-center gap-3">
              <div className={`h-3 w-3 rounded-full ${data ? 'bg-green-500 animate-pulse' : 'bg-yellow-500'}`}></div>
              <span className="font-mono text-lg italic">
                {data ? data.status : "Waiting for Orchestrator..."}
              </span>
            </div>
          </div>

          {data && (
            <div className="grid grid-cols-2 gap-4">
              <div className="p-4 bg-slate-900/50 rounded-lg">
                <p className="text-xs text-slate-500">Engine</p>
                <p className="font-semibold">{data.engine}</p>
              </div>
              <div className="p-4 bg-slate-900/50 rounded-lg">
                <p className="text-xs text-slate-500">Version</p>
                <p className="font-semibold">{data.version}</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
