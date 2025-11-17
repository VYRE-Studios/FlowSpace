import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { WorkspaceRole } from '@prisma/client';

import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../shared/redis.service';
import {
  WorkspaceEvents,
  ChatMessagePayload,
  ChannelCreatedPayload,
} from '../../libs/shared';

interface CreateMessageInput {
  workspaceId: string;
  channelId: string;
  senderId?: string;
  content: string;
  attachments?: string[];
  parentId?: string | null;
}

interface CreateChannelInput {
  workspaceId: string;
  creatorId?: string;
  name: string;
  description?: string;
  private?: boolean;
}

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async listChannels(workspaceId: string, userId?: string) {
    if (userId) {
      const membership = await this.prisma.workspaceMember.findFirst({
        where: { workspaceId, userId },
      });
      if (!membership) {
        throw new ForbiddenException('User is not a member of this workspace');
      }
    }

    const channels = await this.prisma.channel.findMany({
      where: { workspaceId },
      include: {
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          include: { sender: true },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return channels.map((channel) => ({
      id: channel.id,
      name: channel.name,
      description: channel.description,
      updatedAt: channel.updatedAt.toISOString(),
      lastMessage: channel.messages[0]
        ? {
            id: channel.messages[0].id,
            senderId: channel.messages[0].senderId,
            senderName: channel.messages[0].sender.displayName ?? null,
            content: channel.messages[0].content,
            createdAt: channel.messages[0].createdAt.toISOString(),
          }
        : null,
    }));
  }

  async getChannelMessages(
    workspaceId: string,
    channelId: string,
    userId?: string,
    limit = 200,
  ) {
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
      include: { workspace: true },
    });

    if (!channel || channel.workspaceId !== workspaceId) {
      throw new NotFoundException('Channel not found');
    }

    if (userId) {
      const membership = await this.prisma.workspaceMember.findFirst({
        where: { workspaceId, userId },
      });
      if (!membership) {
        throw new ForbiddenException('User is not a member of this workspace');
      }
    }

    const messages = await this.prisma.chatMessage.findMany({
      where: { channelId },
      orderBy: { createdAt: 'asc' },
      take: limit,
      include: { sender: true },
    });

    return {
      channel: {
        id: channel.id,
        name: channel.name,
        description: channel.description,
        workspaceId: channel.workspaceId,
      },
      messages: messages.map((message) => ({
        id: message.id,
        channelId: message.channelId,
        senderId: message.senderId,
        senderName: message.sender.displayName ?? null,
        content: message.content,
        attachments: message.attachments,
        parentId: message.parentId ?? null,
        createdAt: message.createdAt.toISOString(),
      })),
    };
  }

  async createChannel({
    workspaceId,
    creatorId,
    name,
    description,
    private: isPrivate,
  }: CreateChannelInput) {
    if (!creatorId) {
      throw new ForbiddenException('Creator is required');
    }

    const membership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId: creatorId },
      include: {
        workspace: true,
      },
    });

    if (!membership) {
      throw new ForbiddenException('User is not a member of this workspace');
    }

    if (
      membership.role !== WorkspaceRole.OWNER &&
      membership.role !== WorkspaceRole.ADMIN
    ) {
      throw new ForbiddenException('Only workspace admins can create channels');
    }

    const normalizedName = name?.trim();
    if (!normalizedName) {
      throw new BadRequestException('Channel name is required');
    }

    if (description && description.length > 2000) {
      throw new BadRequestException('Description is too long');
    }

    if (isPrivate) {
      throw new BadRequestException('Private channels are not supported yet');
    }

    const duplicate = await this.prisma.channel.findFirst({
      where: {
        workspaceId,
        name: normalizedName,
      },
      select: { id: true },
    });

    if (duplicate) {
      throw new ConflictException('A channel with this name already exists');
    }

    const channel = await this.prisma.channel.create({
      data: {
        workspaceId,
        name: normalizedName,
        description,
      },
    });

    const payload: ChannelCreatedPayload = {
      workspaceId,
      createdBy: creatorId,
      channel: {
        id: channel.id,
        name: channel.name,
        description: channel.description ?? null,
        createdAt: channel.createdAt.toISOString(),
        updatedAt: channel.updatedAt.toISOString(),
      },
    };

    await this.redis.publish(WorkspaceEvents.CHANNEL_CREATED, payload);

    return payload;
  }


  async sendMessage({
    workspaceId,
    channelId,
    senderId,
    content,
    attachments = [],
    parentId = null,
  }: CreateMessageInput) {
    if (!senderId) {
      throw new ForbiddenException('Sender is required');
    }

    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
      include: { workspace: true },
    });

    if (!channel || channel.workspaceId !== workspaceId) {
      throw new NotFoundException('Channel not found');
    }

    const membership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId: senderId },
    });

    if (!membership) {
      throw new ForbiddenException('User is not a member of this workspace');
    }

    // Validate parent message if parentId is provided
    if (parentId) {
      const parentMessage = await this.prisma.chatMessage.findUnique({
        where: { id: parentId },
      });

      if (!parentMessage || parentMessage.channelId !== channelId) {
        throw new NotFoundException('Parent message not found or in different channel');
      }
    }

    const message = await this.prisma.chatMessage.create({
      data: {
        channelId,
        senderId,
        content,
        attachments,
        parentId,
      },
      include: { sender: true },
    });

    await this.prisma.channel.update({
      where: { id: channelId },
      data: { updatedAt: new Date() },
    });

    const payload: ChatMessagePayload = {
      id: message.id,
      channelId: message.channelId,
      senderId: message.senderId,
      senderName: message.sender.displayName ?? null,
      content: message.content,
      attachments: message.attachments,
      parentId: message.parentId ?? null,
      timestamp: message.createdAt.toISOString(),
    };

    await this.redis.publish(WorkspaceEvents.MESSAGE_SENT, {
      workspaceId: channel.workspaceId,
      message: payload,
    });

    return { message: payload };
  }
}