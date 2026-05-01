import {
  Controller,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Req,
  Param,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { VaultService } from './vault.service';
import type { Request } from 'express';

@Controller('workspaces/:workspaceId/upload')
export class UploadController {
  constructor(private readonly vaultService: VaultService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(
    @Req() req: Request & { user?: { id: string } },
    @Param('workspaceId') workspaceId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    const userId = req.user!.id;

    return await this.vaultService.uploadToVault(
      file,
      workspaceId,
      userId,
    );
  }
}
