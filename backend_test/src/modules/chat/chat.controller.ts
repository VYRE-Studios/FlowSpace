import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';

import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('threads')
  getThreads() {
    return this.chatService.getThreads();
  }

  @Get('threads/:id')
  getMessages(@Param('id') threadId: string) {
    return this.chatService.getMessages(threadId);
  }

  @Post('threads')
  createThread(@Body() body: { title: string }) {
    return this.chatService.createThread(body.title);
  }

  @Delete('threads/:id')
  deleteThread(@Param('id') threadId: string) {
    return this.chatService.deleteThread(threadId);
  }

  @Patch('threads/:id')
  renameThread(@Param('id') threadId: string, @Body() body: { title: string }) {
    return this.chatService.renameThread(threadId, body.title);
  }

  @Post('threads/:id/messages')
  sendMessage(
    @Param('id') threadId: string,
    @Body() body: { senderId?: string; content: string },
  ) {
    const senderId = body.senderId ?? 'user-001';
    return this.chatService.sendMessage(threadId, senderId, body.content);
  }
}

