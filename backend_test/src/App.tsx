import { useEffect, useState } from "react";

export function App() {
  const [status, setStatus] = useState<any>(null);
  const [metrics, setMetrics] = useState<any>(null);

  useEffect(() => {
    async function load() {
      const s = await fetch("http://localhost:4000/api/v1/status").then(r => r.json());
      const m = await fetch("http://localhost:4000/api/v1/system/metrics").then(r => r.json());
      setStatus(s);
      setMetrics(m);
    }
    load();
  }, []);

  return (
    <div style={{ backgroundColor: "#0f0f0f", color: "#fff", minHeight: "100vh", padding: "2rem", fontFamily: "monospace" }}>
      <h1>??? Flowspace Dashboard</h1>
      <h2>Status</h2>
      <pre>{JSON.stringify(status, null, 2)}</pre>
      <h2>Metrics</h2>
      <pre>{JSON.stringify(metrics, null, 2)}</pre>
    </div>
  );
}
