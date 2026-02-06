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
