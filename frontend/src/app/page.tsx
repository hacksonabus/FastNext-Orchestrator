"use client";
import { useEffect, useState } from 'react';

export default function Home() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    // Replace <YOUR_SERVER_IP> with your actual Ubuntu server IP
    fetch('http://192.168.1.229:30001/api/health')
      .then(res => res.json())
      .then(setData)
      .catch(err => console.error("Error fetching:", err));
  }, []);

  return (
    <main className="flex min-h-screen flex-col items-center p-24 bg-gray-900 text-white">
      <h1 className="text-4xl font-bold mb-8">POC Dashboard</h1>
      <div className="p-6 bg-gray-800 rounded-xl border border-blue-500 shadow-lg">
        <h2 className="text-xl mb-2">Backend Response:</h2>
        <pre className="bg-black p-4 rounded text-green-400">
          {data ? JSON.stringify(data, null, 2) : "Connecting to FastAPI..."}
        </pre>
      </div>
    </main>
  );
}
