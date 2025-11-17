import { Controller, Get } from '@nestjs/common';

@Controller('api/v1/meet')
export class MeetController {
  @Get('sessions')
  findAll() {
    const now = new Date().toISOString();

    return {
      meetings: [
        { id: 'm1', title: 'Weekly Sync', participants: 3, startedAt: now },
        { id: 'm2', title: 'Design Review', participants: 4, startedAt: now },
      ],
    };
  }
}

