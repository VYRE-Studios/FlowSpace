import { Controller, Get, Res, UseGuards, StreamableFile } from '@nestjs/common';
import { Response } from 'express';
import { createReadStream, statSync } from 'fs';
import { join } from 'path';
import { BasicAuthGuard } from './basic-auth.guard';

@Controller('downloads')
@UseGuards(BasicAuthGuard)
export class DownloadsController {
  private getFilePath(filename: string): string {
    // On Render, files are in /opt/render/project/src/public
    // process.cwd() returns /opt/render/project/src
    const basePath = process.cwd();
    return join(basePath, 'public', 'flo-installer', filename);
  }

  @Get('RELEASES')
  getReleases(@Res({ passthrough: true }) res: Response): StreamableFile {
    const filePath = this.getFilePath('RELEASES');
    const file = createReadStream(filePath);
    const stats = statSync(filePath);

    res.set({
      'Content-Type': 'text/plain',
      'Content-Length': stats.size,
      'Cache-Control': 'no-cache, must-revalidate',
    });

    return new StreamableFile(file);
  }

  @Get('FlowSpace-1.1.0-full.nupkg')
  getPackage(@Res({ passthrough: true }) res: Response): StreamableFile {
    const filePath = this.getFilePath('FlowSpace-1.1.0-full.nupkg');
    const file = createReadStream(filePath);
    const stats = statSync(filePath);

    res.set({
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': 'attachment; filename="FlowSpace-1.1.0-full.nupkg"',
      'Content-Length': stats.size,
      'Cache-Control': 'public, max-age=31536000',
    });

    return new StreamableFile(file);
  }

  @Get('FlowSpaceSetup.exe')
  getSetup(@Res({ passthrough: true }) res: Response): StreamableFile {
    const filePath = this.getFilePath('FlowSpaceSetup.exe');
    const file = createReadStream(filePath);
    const stats = statSync(filePath);

    res.set({
      'Content-Type': 'application/x-msdownload',
      'Content-Disposition': 'attachment; filename="FlowSpaceSetup.exe"',
      'Content-Length': stats.size,
    });

    return new StreamableFile(file);
  }
}
