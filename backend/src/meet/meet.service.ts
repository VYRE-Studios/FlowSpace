import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MeetingStatus } from '@prisma/client';
import { AccessToken } from 'livekit-server-sdk';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class MeetService {
  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async createMeeting(data: {
    workspaceId: string;
    title: string;
    creatorId?: string;
  }) {
    const roomId = `room-${Date.now()}-${Math.random().toString(36).substring(7)}`;

    const meeting = await this.prisma.meeting.create({
      data: {
        workspaceId: data.workspaceId,
        title: data.title,
        roomId,
        status: MeetingStatus.SCHEDULED,
      },
    });

    return meeting;
  }

  async getMeetings(workspaceId?: string) {
    const where = workspaceId
      ? { workspaceId, status: MeetingStatus.ACTIVE }
      : { status: MeetingStatus.ACTIVE };

    const meetings = await this.prisma.meeting.findMany({
      where,
      include: {
        participants: true,
      },
      orderBy: {
        startedAt: 'desc',
      },
      take: 50,
    });

    return meetings.map((meeting) => ({
      id: meeting.id,
      title: meeting.title,
      roomId: meeting.roomId,
      status: meeting.status,
      startedAt: meeting.startedAt,
      participants: meeting.participants.length,
    }));
  }

  async getMeeting(meetingId: string) {
    const meeting = await this.prisma.meeting.findUnique({
      where: { id: meetingId },
      include: {
        participants: true,
      },
    });

    if (!meeting) {
      throw new NotFoundException('Meeting not found');
    }

    return meeting;
  }

  async startMeeting(meetingId: string) {
    const meeting = await this.prisma.meeting.update({
      where: { id: meetingId },
      data: {
        status: MeetingStatus.ACTIVE,
        startedAt: new Date(),
      },
    });

    return meeting;
  }

  async endMeeting(meetingId: string) {
    const meeting = await this.prisma.meeting.update({
      where: { id: meetingId },
      data: {
        status: MeetingStatus.ENDED,
        endedAt: new Date(),
      },
    });

    return meeting;
  }

  async joinMeeting(meetingId: string, userId: string) {
    const existing = await this.prisma.meetingParticipant.findUnique({
      where: {
        meetingId_userId: {
          meetingId,
          userId,
        },
      },
    });

    if (existing && !existing.leftAt) {
      return existing;
    }

    if (existing) {
      return this.prisma.meetingParticipant.update({
        where: { id: existing.id },
        data: {
          joinedAt: new Date(),
          leftAt: null,
        },
      });
    }

    return this.prisma.meetingParticipant.create({
      data: {
        meetingId,
        userId,
      },
    });
  }

  async generateLiveKitToken(roomName: string, participantName: string, participantId: string) {
    const apiKey = this.config.get<string>('LIVEKIT_API_KEY');
    const apiSecret = this.config.get<string>('LIVEKIT_API_SECRET');
    const livekitUrl = this.config.get<string>('LIVEKIT_URL');

    if (!apiKey || !apiSecret || !livekitUrl) {
      throw new Error('LiveKit credentials not configured');
    }

    const at = new AccessToken(apiKey, apiSecret, {
      identity: participantId,
      name: participantName,
    });

    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
    });

    const token = await at.toJwt();

    return {
      token,
      url: livekitUrl,
      roomName,
    };
  }

  async leaveMeeting(meetingId: string, userId: string) {
    const participant = await this.prisma.meetingParticipant.findUnique({
      where: {
        meetingId_userId: {
          meetingId,
          userId,
        },
      },
    });

    if (!participant) {
      throw new NotFoundException('Participant not found');
    }

    return this.prisma.meetingParticipant.update({
      where: { id: participant.id },
      data: {
        leftAt: new Date(),
      },
    });
  }
}
