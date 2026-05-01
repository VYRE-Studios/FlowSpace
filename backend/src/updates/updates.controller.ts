import { Controller, Get, Query } from '@nestjs/common';
import { UpdatesService } from './updates.service';

@Controller('updates')
export class UpdatesController {
  constructor(private readonly updatesService: UpdatesService) {}

  @Get('check')
  async checkForUpdates(
    @Query('version') version: string,
    @Query('build') build: string,
    @Query('platform') platform: string = 'windows',
  ) {
    return this.updatesService.checkForUpdates(version, build, platform);
  }

  @Get('latest')
  async getLatestVersion(@Query('platform') platform: string = 'windows') {
    return this.updatesService.getLatestVersion(platform);
  }
}

