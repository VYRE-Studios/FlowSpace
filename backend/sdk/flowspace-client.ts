export class FlowspaceClient {
  constructor(base = "http://localhost:4000/api/v1") {
    this.base = base;
  }

  async getStatus() {
    return fetch(`${this.base}/status`).then(r => r.json());
  }

  async getMetrics() {
    return fetch(`${this.base}/system/metrics`).then(r => r.json());
  }

  async createUser(data) {
    return fetch(`${this.base}/auth/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data)
    }).then(r => r.json());
  }

  async registerNode(nodeId, address) {
    return fetch(`${this.base}/registry/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nodeId, address })
    }).then(r => r.json());
  }
}
