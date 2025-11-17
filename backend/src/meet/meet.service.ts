import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaClient, MeetingStatus } from '@prisma/client';

const prisma = new PrismaClient();

@Injectable()
export class MeetService {
  async createMeeting(data: {
    workspaceId: string;
    title: string;
    creatorId?: string;
  }) {
    const roomId = `room-${Date.now()}-${Math.random().toString(36).substring(7)}`;

    const meeting = await prisma.meeting.create({
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

    const meetings = await prisma.meeting.findMany({
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
    const meeting = await prisma.meeting.findUnique({
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
    const meeting = await prisma.meeting.update({
      where: { id: meetingId },
      data: {
        status: MeetingStatus.ACTIVE,
        startedAt: new Date(),
      },
    });

    return meeting;
  }

  async endMeeting(meetingId: string) {
    const meeting = await prisma.meeting.update({
      where: { id: meetingId },
      data: {
        status: MeetingStatus.ENDED,
        endedAt: new Date(),
      },
    });

    return meeting;
  }

  async joinMeeting(meetingId: string, userId: string) {
    const existing = await prisma.meetingParticipant.findUnique({
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
      return prisma.meetingParticipant.update({
        where: { id: existing.id },
        data: {
          joinedAt: new Date(),
          leftAt: null,
        },
      });
    }

    return prisma.meetingParticipant.create({
      data: {
        meetingId,
        userId,
      },
    });
  }

  async leaveMeeting(meetingId: string, userId: string) {
    const participant = await prisma.meetingParticipant.findUnique({
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

    return prisma.meetingParticipant.update({
      where: { id: participant.id },
      data: {
        leftAt: new Date(),
      },
    });
  }
}
