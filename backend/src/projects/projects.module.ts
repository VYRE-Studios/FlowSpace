import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../database/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { ProjectsController } from './projects.controller';
import { ProjectsService } from './projects.service';
import { TemplateService } from './template.service';

@Module({
  imports: [ConfigModule, PrismaModule, AuthModule],
  controllers: [ProjectsController],
  providers: [ProjectsService, TemplateService],
  exports: [ProjectsService],
})
export class ProjectsModule {}

