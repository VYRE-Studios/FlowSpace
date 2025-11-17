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

import { KratosSessionGuard } from '../auth/kratos-session.guard';
import { ChatService } from './chat.service';

@Controller('workspaces/:workspaceId/channels')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @UseGuards(KratosSessionGuard)
  @Get()
  listChannels(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
  ) {
    return this.chatService.listChannels(workspaceId, req.user?.id);
  }

  @UseGuards(KratosSessionGuard)
  @Post()
  createChannel(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Body() body: { name: string; description?: string; private?: boolean },
  ) {
    return this.chatService.createChannel({
      workspaceId,
      creatorId: req.user?.id,
      name: body.name,
      description: body.description,
      private: body.private ?? false,
    });
  }

  @UseGuards(KratosSessionGuard)
  @Get(':channelId/messages')
  getMessages(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Param('channelId') channelId: string,
    @Query('limit') limit?: string,
  ) {
    const take = limit ? Math.min(parseInt(limit, 10), 500) : 200;
    return this.chatService.getChannelMessages(
      workspaceId,
      channelId,
      req.user?.id,
      take,
    );
  }

  @UseGuards(KratosSessionGuard)
  @Post(':channelId/messages')
  createMessage(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Param('channelId') channelId: string,
    @Body()
    body: {
      content: string;
      attachments?: string[];
      parentId?: string | null;
    },
  ) {
    return this.chatService.sendMessage({
      workspaceId,
      channelId,
      senderId: req.user?.id,
      content: body.content,
      attachments: body.attachments ?? [],
      parentId: body.parentId ?? null,
    });
  }
}