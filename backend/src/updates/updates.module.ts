import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { UpdatesController } from './updates.controller';
import { UpdatesService } from './updates.service';
import { PrismaModule } from '../database/prisma.module';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [UpdatesController],
  providers: [UpdatesService],
  exports: [UpdatesService],
})
export class UpdatesModule {}

