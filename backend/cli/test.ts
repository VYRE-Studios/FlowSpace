import { FlowspaceClient } from "../sdk/flowspace-client";

async function main() {
  const fs = new FlowspaceClient();
  console.log("Status:", await fs.getStatus());
  console.log("Metrics:", await fs.getMetrics());
}
main();
