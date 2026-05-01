import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { PrismaModule } from '../database/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { VaultController } from './vault.controller';
import { VaultService } from './vault.service';
import { UploadController } from './upload.controller';

@Module({
  imports: [ConfigModule, PrismaModule, AuthModule],
  controllers: [VaultController, UploadController],
  providers: [VaultService],
})
export class VaultModule {}