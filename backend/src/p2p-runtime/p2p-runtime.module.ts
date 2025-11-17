import { Module } from '@nestjs/common';
import { PrismaModule } from '../database/prisma.module';
import { P2PRuntimeService } from './p2p-runtime.service';
import { P2PRuntimeController } from './p2p-runtime.controller';

@Module({
  imports: [PrismaModule],
  controllers: [P2PRuntimeController],
  providers: [P2PRuntimeService],
  exports: [P2PRuntimeService],
})
export class P2PRuntimeModule {}

