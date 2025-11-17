import { Module } from '@nestjs/common';

import { PrismaModule } from '../database/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { WorkspacesController } from './workspaces.controller';
import { WorkspacesService } from './workspaces.service';
import { WorkspaceFilesystemService } from './workspace-filesystem.service';
import { WorkspaceVaultSyncService } from './workspace-vault-sync.service';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [WorkspacesController],
  providers: [
    WorkspacesService,
    WorkspaceFilesystemService,
    WorkspaceVaultSyncService,
  ],
  exports: [WorkspacesService],
})
export class WorkspacesModule {}
