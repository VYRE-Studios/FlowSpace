import { Module } from '@nestjs/common';
import { TaskService } from './task.service';
import { SystemController } from './system.controller';
import { AuditService } from './audit.service';
import { PrismaModule } from '../database/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  providers: [TaskService, AuditService],
  controllers: [SystemController],
  exports: [AuditService],
})
export class SystemModule {}
