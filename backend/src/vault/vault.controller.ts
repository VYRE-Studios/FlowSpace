import type { Express } from 'express';
import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/jwt.guard';
import { VaultService } from './vault.service';

@Controller('vault')
export class VaultController {
  constructor(private readonly vault: VaultService) {}

  @UseGuards(JwtAuthGuard)
  @Post(':workspaceId/upload')
  @UseInterceptors(FileInterceptor('file', { storage: memoryStorage() }))
  uploadFile(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('uploaderId') uploaderId?: string,
  ) {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const resolvedUploader = uploaderId ?? req.user?.id;
    if (!resolvedUploader) {
      throw new BadRequestException('uploaderId is required');
    }

    return this.vault.uploadToVault(file, workspaceId, resolvedUploader);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':workspaceId/recent')
  listRecent(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Query('limit') limit?: string,
  ) {
    const take = limit ? Math.min(parseInt(limit, 10), 50) : 20;
    return this.vault.listRecentFiles(workspaceId, req.user?.id, take);
  }

  @UseGuards(JwtAuthGuard)
  @Get('files/:fileId')
  getFile(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('fileId') fileId: string,
  ) {
    return this.vault.getFile(fileId, req.user?.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('files/:fileId/delete')
  deleteFile(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('fileId') fileId: string,
  ) {
    if (!req.user?.id) {
      throw new BadRequestException('User not authenticated');
    }
    return this.vault.deleteFile(fileId, req.user.id);
  }
}
