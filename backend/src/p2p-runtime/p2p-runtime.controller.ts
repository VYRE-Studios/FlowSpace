import { Controller, Get } from '@nestjs/common';
import { P2PRuntimeService } from './p2p-runtime.service';

@Controller('p2p')
export class P2PRuntimeController {
  constructor(private readonly p2pRuntime: P2PRuntimeService) {}

  @Get('status')
  async getStatus() {
    const identity = await this.p2pRuntime.getIdentity();
    const status = await this.p2pRuntime.getStatus();
    const peers = await this.p2pRuntime.getPeerList();

    return {
      nodeId: identity.nodeId,
      publicKey: identity.publicKey,
      runtimeState: status.online ? 'running' : 'stopped',
      discovery: 'active',
      peers,
      queueSize: status.queueSize,
      lastHeartbeat: Date.now(),
    };
  }

  @Get('peers')
  async getPeers() {
    return this.p2pRuntime.getPeerList();
  }

  @Get('identity')
  async getIdentity() {
    return this.p2pRuntime.getIdentity();
  }
}
