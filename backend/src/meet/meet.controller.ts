import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/jwt.guard';
import { MeetService } from './meet.service';

@Controller('meet')
export class MeetController {
  constructor(private readonly meetService: MeetService) {}

  @UseGuards(JwtAuthGuard)
  @Get('sessions')
  async findAll(
    @Query('workspaceId') workspaceId?: string,
  ) {
    const meetings = await this.meetService.getMeetings(workspaceId);
    return { meetings };
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  async create(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body()
    body: {
      workspaceId: string;
      title: string;
    },
  ) {
    return this.meetService.createMeeting({
      workspaceId: body.workspaceId,
      title: body.title,
      creatorId: req.user?.id,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Post(':meetingId/start')
  async start(@Param('meetingId') meetingId: string) {
    return this.meetService.startMeeting(meetingId);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':meetingId/end')
  async end(@Param('meetingId') meetingId: string) {
    return this.meetService.endMeeting(meetingId);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':meetingId/join')
  async join(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('meetingId') meetingId: string,
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.meetService.joinMeeting(meetingId, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':meetingId/leave')
  async leave(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('meetingId') meetingId: string,
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.meetService.leaveMeeting(meetingId, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':meetingId/token')
  async getToken(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('meetingId') meetingId: string,
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }

    const meeting = await this.meetService.getMeeting(meetingId);
    const participantName = req.user.displayName || req.user.email || 'User';

    return this.meetService.generateLiveKitToken(
      meeting.roomId,
      participantName,
      req.user.id,
    );
  }
}
