import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../database/prisma.service';
import { WorkspaceFilesystemService } from './workspace-filesystem.service';
import { WorkspaceVaultSyncService } from './workspace-vault-sync.service';

@Injectable()
export class WorkspacesService {
  private readonly defaultChannels: Array<Pick<Prisma.ChannelCreateWithoutWorkspaceInput, 'name' | 'description'>> = [
    {
      name: 'general',
      description: 'Announcements, updates, and company-wide conversations.',
    },
    {
      name: 'engineering',
      description: 'Shipping updates, pull requests, and technical chatter.',
    },
    {
      name: 'random',
      description: 'Watercooler banter, memes, and everything in between.',
    },
  ];

  constructor(
    private readonly prisma: PrismaService,
    private readonly filesystemService: WorkspaceFilesystemService,
    private readonly vaultSyncService: WorkspaceVaultSyncService,
  ) {}

  async listForUser(identifier: { userId?: string; email?: string }) {
    let targetUserId = identifier.userId;

    if (!targetUserId && identifier.email) {
      const lookup = await this.prisma.user.findUnique({
        where: { email: identifier.email },
      });

      if (!lookup) {
        throw new NotFoundException('User not found');
      }

      targetUserId = lookup.id;
    }

    if (!targetUserId) {
      throw new NotFoundException('User identifier is required');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: targetUserId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    await this.ensureBootstrapWorkspace(user);

    const memberships = await this.prisma.workspaceMember.findMany({
      where: { userId: targetUserId },
      include: {
        workspace: {
          include: {
            channels: {
              orderBy: { createdAt: 'asc' },
            },
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    const workspaces = memberships.map((membership) => ({
      id: membership.workspace.id,
      slug: membership.workspace.slug,
      name: membership.workspace.name,
      description: membership.workspace.description,
      role: membership.role,
      channelCount: membership.workspace.channels.length,
      channels: membership.workspace.channels.map((channel) => ({
        id: channel.id,
        name: channel.name,
        description: channel.description,
        createdAt: channel.createdAt.toISOString(),
        updatedAt: channel.updatedAt.toISOString(),
      })),
      createdAt: membership.workspace.createdAt.toISOString(),
      updatedAt: membership.workspace.updatedAt.toISOString(),
    }));

    return {
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
      workspaces,
    };
  }

  async createWorkspace(name: string, ownerId?: string, description?: string) {
    if (!ownerId) {
      throw new NotFoundException('Owner identifier is required');
    }

    const slug = await this.generateUniqueSlug(name);

    // Create local workspace directory
    const directoryStructure = await this.filesystemService.createWorkspaceDirectory(slug, name);

    // Create workspace in database
    const workspace = await this.prisma.workspace.create({
      data: {
        name,
        description,
        slug,
        ownerId,
        members: {
          create: { userId: ownerId, role: 'OWNER' },
        },
        channels: {
          create: this.defaultChannels,
        },
      },
      include: {
        owner: true,
        channels: {
          orderBy: { createdAt: 'asc' },
        },
        members: {
          include: {
            user: true,
          },
        },
      },
    });

    // Initial sync to vault (creates the workspace folder in MinIO)
    await this.vaultSyncService.syncWorkspaceToVault(slug).catch(error => {
      console.error(`Failed initial vault sync for workspace ${slug}:`, error);
    });

    return {
      id: workspace.id,
      slug: workspace.slug,
      name: workspace.name,
      description: workspace.description,
      owner: {
        id: workspace.owner.id,
        email: workspace.owner.email,
        displayName: workspace.owner.displayName,
      },
      channels: workspace.channels.map((channel) => ({
        id: channel.id,
        name: channel.name,
        description: channel.description,
        createdAt: channel.createdAt.toISOString(),
        updatedAt: channel.updatedAt.toISOString(),
      })),
      members: workspace.members.map((member) => ({
        id: member.id,
        userId: member.userId,
        role: member.role,
        displayName: member.user.displayName ?? member.user.email,
        joinedAt: member.createdAt.toISOString(),
      })),
    };
  }

  async getWorkspaceChannels(workspaceId: string, userId?: string) {
    if (userId) {
      const membership = await this.prisma.workspaceMember.findFirst({
        where: { workspaceId, userId },
      });

      if (!membership) {
        throw new ForbiddenException('User is not a member of this workspace');
      }
    }

    const workspace = await this.prisma.workspace.findUnique({
      where: { id: workspaceId },
      include: {
        channels: {
          orderBy: { updatedAt: 'desc' },
        },
      },
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    return {
      id: workspace.id,
      name: workspace.name,
      channels: workspace.channels.map((channel) => ({
        id: channel.id,
        name: channel.name,
        description: channel.description,
      })),
    };
  }

  private async ensureBootstrapWorkspace(user: {
    id: string;
    email: string;
    displayName: string | null;
  }) {
    const existingCount = await this.prisma.workspaceMember.count({
      where: { userId: user.id },
    });

    if (existingCount > 0) {
      return;
    }

    // FIXED: Add all new users to the main workspace instead of creating personal workspaces
    const MAIN_WORKSPACE_SLUG = 'vyrevault-studios';
    
    // Check if main workspace exists
    const mainWorkspace = await this.prisma.workspace.findUnique({
      where: { slug: MAIN_WORKSPACE_SLUG },
    });

    if (mainWorkspace) {
      // Add user to main workspace
      await this.prisma.workspaceMember.create({
        data: {
          workspaceId: mainWorkspace.id,
          userId: user.id,
          role: 'MEMBER',
        },
      });
      console.log(`[WorkspaceService] Auto-added user ${user.email} to main workspace "${mainWorkspace.name}"`);
    } else {
      // Fallback: create personal workspace if main workspace doesn't exist
      console.warn(`[WorkspaceService] Main workspace "${MAIN_WORKSPACE_SLUG}" not found, creating personal workspace for ${user.email}`);
      const inferredName =
        user.displayName ??
        (user.email ? `${user.email.split('@')[0]}'s Space` : 'My Workspace');
      await this.createWorkspace(inferredName, user.id, 'Default workspace');
    }
  }

  private async generateUniqueSlug(name: string): Promise<string> {
    const base = name
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '') || 'workspace';

    let candidate = base;
    let counter = 1;

    // eslint-disable-next-line no-constant-condition
    while (true) {
      const exists = await this.prisma.workspace.findUnique({
        where: { slug: candidate },
        select: { id: true },
      });

      if (!exists) {
        return candidate;
      }

      candidate = `${base}-${counter++}`;
    }
  }

  async ensureUserProfile(user?: {
    id: string;
    email?: string;
    displayName?: string | null;
  }): Promise<void> {
    if (!user?.id) {
      return;
    }

    const email = user.email ?? `${user.id}@identity.flowspace`;
    const displayName = user.displayName ?? email;

    await this.prisma.user.upsert({
      where: { id: user.id },
      update: {
        email,
        displayName,
      },
      create: {
        id: user.id,
        email,
        displayName,
        passwordHash: 'kratos-managed',
      },
    });
  }

  async addMember(workspaceId: string, userEmail: string, requesterId: string) {
    // Check if requester has permission
    const requesterMembership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId: requesterId },
    });

    if (!requesterMembership || (requesterMembership.role !== 'OWNER' && requesterMembership.role !== 'ADMIN')) {
      throw new ForbiddenException('Only workspace owners and admins can add members');
    }

    // Find user by email
    const user = await this.prisma.user.findUnique({
      where: { email: userEmail },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if already a member
    const existing = await this.prisma.workspaceMember.findUnique({
      where: {
        workspaceId_userId: {
          workspaceId,
          userId: user.id,
        },
      },
    });

    if (existing) {
      throw new ForbiddenException('User is already a member');
    }

    const member = await this.prisma.workspaceMember.create({
      data: {
        workspaceId,
        userId: user.id,
        role: 'MEMBER',
      },
      include: {
        user: true,
      },
    });

    return {
      id: member.id,
      userId: member.userId,
      role: member.role,
      email: member.user.email,
      displayName: member.user.displayName,
      joinedAt: member.createdAt.toISOString(),
    };
  }

  async removeMember(workspaceId: string, targetUserId: string, requesterId: string) {
    // Check if requester has permission
    const requesterMembership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId: requesterId },
    });

    if (!requesterMembership || (requesterMembership.role !== 'OWNER' && requesterMembership.role !== 'ADMIN')) {
      throw new ForbiddenException('Only workspace owners and admins can remove members');
    }

    // Can't remove the owner
    const targetMembership = await this.prisma.workspaceMember.findUnique({
      where: {
        workspaceId_userId: {
          workspaceId,
          userId: targetUserId,
        },
      },
    });

    if (!targetMembership) {
      throw new NotFoundException('Member not found');
    }

    if (targetMembership.role === 'OWNER') {
      throw new ForbiddenException('Cannot remove workspace owner');
    }

    await this.prisma.workspaceMember.delete({
      where: { id: targetMembership.id },
    });

    return { success: true };
  }

  async updateMemberRole(
    workspaceId: string,
    targetUserId: string,
    newRole: 'ADMIN' | 'MEMBER',
    requesterId: string,
  ) {
    // Only owner can change roles
    const requesterMembership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId: requesterId },
    });

    if (!requesterMembership || requesterMembership.role !== 'OWNER') {
      throw new ForbiddenException('Only workspace owner can change member roles');
    }

    const targetMembership = await this.prisma.workspaceMember.findUnique({
      where: {
        workspaceId_userId: {
          workspaceId,
          userId: targetUserId,
        },
      },
    });

    if (!targetMembership) {
      throw new NotFoundException('Member not found');
    }

    if (targetMembership.role === 'OWNER') {
      throw new ForbiddenException('Cannot change owner role');
    }

    const updated = await this.prisma.workspaceMember.update({
      where: { id: targetMembership.id },
      data: { role: newRole },
      include: { user: true },
    });

    return {
      id: updated.id,
      userId: updated.userId,
      role: updated.role,
      email: updated.user.email,
      displayName: updated.user.displayName,
    };
  }

  async deleteWorkspace(workspaceId: string, requesterId: string) {
    const membership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId: requesterId },
    });

    if (!membership || membership.role !== 'OWNER') {
      throw new ForbiddenException('Only workspace owner can delete workspace');
    }

    await this.prisma.workspace.delete({
      where: { id: workspaceId },
    });

    return { success: true };
  }

  async getMembers(workspaceId: string, requesterId?: string) {
    if (requesterId) {
      const membership = await this.prisma.workspaceMember.findFirst({
        where: { workspaceId, userId: requesterId },
      });

      if (!membership) {
        throw new ForbiddenException('Not a member of this workspace');
      }
    }

    const members = await this.prisma.workspaceMember.findMany({
      where: { workspaceId },
      include: { user: true },
      orderBy: { createdAt: 'asc' },
    });

    return members.map((m) => ({
      id: m.id,
      userId: m.userId,
      role: m.role,
      email: m.user.email,
      displayName: m.user.displayName,
      joinedAt: m.createdAt.toISOString(),
    }));
  }
}
