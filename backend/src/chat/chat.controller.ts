import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/jwt.guard';
import { ChatService } from './chat.service';

@Controller('workspaces/:workspaceId/channels')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  listChannels(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
  ) {
    return this.chatService.listChannels(workspaceId, req.user?.id);
  }

  @UseGuards(JwtAuthGuard)
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

  @UseGuards(JwtAuthGuard)
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

  @UseGuards(JwtAuthGuard)
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

  @UseGuards(JwtAuthGuard)
  @Post('messages/:messageId/reactions')
  addReaction(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
    @Body() body: { emoji: string },
  ) {
    return this.chatService.addReaction(
      messageId,
      req.user!.id,
      body.emoji,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Delete('messages/:messageId/reactions')
  removeReaction(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
    @Query('emoji') emoji: string,
  ) {
    return this.chatService.removeReaction(messageId, req.user!.id, emoji);
  }

  @UseGuards(JwtAuthGuard)
  @Put('messages/:messageId')
  editMessage(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
    @Body() body: { content: string },
  ) {
    return this.chatService.editMessage(
      messageId,
      req.user!.id,
      body.content,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Delete('messages/:messageId')
  deleteMessage(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
  ) {
    return this.chatService.deleteMessage(messageId, req.user!.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('messages/:messageId/thread')
  getThread(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
  ) {
    return this.chatService.getThreadMessages(messageId, req.user?.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('messages/:messageId/read')
  markAsRead(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
  ) {
    return this.chatService.markAsRead(messageId, req.user!.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('messages/:messageId/reads')
  getReadReceipts(@Param('messageId') messageId: string) {
    return this.chatService.getReadReceipts(messageId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('messages/:messageId/pin')
  pinMessage(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
  ) {
    return this.chatService.pinMessage(messageId, req.user!.id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('messages/:messageId/pin')
  unpinMessage(
    @Req() req: Request & { user?: { id: string } },
    @Param('messageId') messageId: string,
  ) {
    return this.chatService.unpinMessage(messageId, req.user!.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':channelId/pinned')
  getPinnedMessages(
    @Req() req: Request & { user?: { id: string } },
    @Param('channelId') channelId: string,
  ) {
    return this.chatService.getPinnedMessages(channelId, req.user?.id);
  }
}
