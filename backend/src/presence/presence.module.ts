import { Module } from '@nestjs/common';

import { SharedModule } from '../shared/shared.module';
import { AuthModule } from '../auth/auth.module';
import { PresenceGateway } from './presence.gateway';

@Module({
  imports: [SharedModule, AuthModule],
  providers: [PresenceGateway],
})
export class PresenceModule {}