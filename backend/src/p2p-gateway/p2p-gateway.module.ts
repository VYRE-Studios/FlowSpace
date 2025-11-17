import { Module } from '@nestjs/common';

import { P2PGateway } from './p2p-gateway.gateway';
import { P2PGatewayService } from './p2p-gateway.service';
import { P2PRuntimeModule } from '../p2p-runtime/p2p-runtime.module';

@Module({
  imports: [P2PRuntimeModule],
  providers: [P2PGateway, P2PGatewayService],
  exports: [P2PGatewayService],
})
export class P2PGatewayModule {}

