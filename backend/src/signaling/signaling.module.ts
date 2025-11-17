import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from '../auth/auth.module';
import { SignalingController } from './signaling.controller';
import { SignalingService } from './signaling.service';

@Module({
  imports: [ConfigModule, AuthModule],
  controllers: [SignalingController],
  providers: [SignalingService],
})
export class SignalingModule {}