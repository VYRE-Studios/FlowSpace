export interface ChatMessagePayload {
  id: string;
  channelId: string;
  senderId: string;
  senderName?: string | null;
  content: string;
  timestamp: string;
  attachments?: string[];
  parentId?: string | null;
}

export interface PresenceUpdatePayload {
  workspaceId: string;
  userId: string;
  status: 'online' | 'offline' | 'away';
  lastActiveAt: string;
}

export interface ChannelCreatedPayload {
  workspaceId: string;
  channel: {
    id: string;
    name: string;
    description?: string | null;
    createdAt: string;
    updatedAt: string;
  };
  createdBy: string;
}
