import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { PrismaModule } from '../database/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { VaultController } from './vault.controller';
import { VaultService } from './vault.service';

@Module({
  imports: [ConfigModule, PrismaModule, AuthModule],
  controllers: [VaultController],
  providers: [VaultService],
})
export class VaultModule {}