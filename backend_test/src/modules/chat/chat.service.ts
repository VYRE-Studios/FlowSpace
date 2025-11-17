import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';

type ThreadWithMessages = Prisma.ChatThread & {
  messages: Prisma.ChatMessage[];
};

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async getThreads() {
    const threads = await this.prisma.chatThread.findMany({
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return {
      threads: threads.map((thread: ThreadWithMessages) => {
        const participants = Array.from(
          new Set(
            thread.messages.map(
              (message: Prisma.ChatMessage) =>
                message.senderName ?? message.senderId,
            ),
          ),
        );
        const lastMessage = thread.messages.length
          ? thread.messages[thread.messages.length - 1].content
          : null;

        return {
          id: thread.id,
          title: thread.title,
          participants,
          lastMessage,
          updatedAt: thread.updatedAt,
        };
      }),
    };
  }

  async getMessages(threadId: string) {
    const thread = await this.prisma.chatThread.findUnique({
      where: { id: threadId },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!thread) {
      throw new NotFoundException('Thread not found');
    }

    const participants = Array.from(
      new Set(
        thread.messages.map(
          (message: Prisma.ChatMessage) =>
            message.senderName ?? message.senderId,
        ),
      ),
    );
    const lastMessage = thread.messages.length
      ? thread.messages[thread.messages.length - 1].content
      : null;

    return {
      thread: {
        id: thread.id,
        title: thread.title,
        participants,
        lastMessage,
        updatedAt: thread.updatedAt,
      },
      messages: thread.messages.map((message: Prisma.ChatMessage) => ({
        id: message.id,
        threadId: message.threadId,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        createdAt: message.createdAt,
      })),
    };
  }

  async createThread(title: string) {
    return this.prisma.chatThread.create({
      data: {
        title,
      },
    });
  }

  async deleteThread(id: string) {
    return this.prisma.chatThread.delete({
      where: { id },
    });
  }

  async renameThread(id: string, title: string) {
    return this.prisma.chatThread.update({
      where: { id },
      data: { title },
    });
  }

  async sendMessage(threadId: string, senderId: string, content: string) {
    const thread = await this.prisma.chatThread.findUnique({
      where: { id: threadId },
    });

    if (!thread) {
      throw new NotFoundException('Thread not found');
    }

    const message = await this.prisma.chatMessage.create({
      data: {
        threadId,
        senderId,
        senderName: this.resolveDisplayName(senderId),
        content,
      },
    });

    await this.prisma.chatThread.update({
      where: { id: threadId },
      data: { updatedAt: new Date() },
    });

    return {
      message: {
        id: message.id,
        threadId: message.threadId,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        createdAt: message.createdAt,
      },
    };
  }

  private resolveDisplayName(senderId: string): string {
    if (senderId === 'user-001') {
      return 'Flowspace Operator';
    }
    if (senderId === 'user-002') {
      return 'Mission Control';
    }
    return senderId;
  }
}

