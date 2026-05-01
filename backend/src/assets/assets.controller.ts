import { Controller, Get, Res, Param } from '@nestjs/common';
import { Response } from 'express';
import { join } from 'path';
import { existsSync } from 'fs';

@Controller('assets/sounds')
export class AssetsController {
  private readonly soundsPath = join(process.cwd(), 'assets', 'sounds');

  @Get(':filename')
  async getSound(@Param('filename') filename: string, @Res() res: Response) {
    // Validate filename to prevent directory traversal
    if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
      return res.status(400).json({ error: 'Invalid filename' });
    }

    // Only allow specific audio file extensions
    const allowedExtensions = ['.wav', '.mp3', '.ogg'];
    const hasValidExtension = allowedExtensions.some(ext => filename.endsWith(ext));
    
    if (!hasValidExtension) {
      return res.status(400).json({ error: 'Invalid file type' });
    }

    const filePath = join(this.soundsPath, filename);

    // Check if file exists
    if (!existsSync(filePath)) {
      return res.status(404).json({ error: 'Sound file not found' });
    }

    // Set appropriate content type
    let contentType = 'audio/wav';
    if (filename.endsWith('.mp3')) {
      contentType = 'audio/mpeg';
    } else if (filename.endsWith('.ogg')) {
      contentType = 'audio/ogg';
    }

    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 1 day
    res.sendFile(filePath);
  }

  @Get()
  async listSounds() {
    return {
      sounds: {
        notification: 'notification.wav',
        clockBeep: 'clockbeep.mp3',
        whoosh: 'whoosh.mp3',
      },
      baseUrl: '/assets/sounds',
    };
  }
}
