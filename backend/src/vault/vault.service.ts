import type { Express } from 'express';
import { ForbiddenException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

import { PrismaService } from '../database/prisma.service';

@Injectable()
export class VaultService {
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly publicEndpoint: string;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const endpoint = this.config.get<string>('MINIO_ENDPOINT');
    const accessKey = this.config.get<string>('MINIO_ACCESS_KEY');
    const secretKey = this.config.get<string>('MINIO_SECRET_KEY');

    if (!endpoint || !accessKey || !secretKey) {
      throw new Error('MinIO configuration is missing.');
    }

    this.bucket = this.config.get<string>('MINIO_BUCKET') ?? 'flowspace';
    this.publicEndpoint =
      this.config.get<string>('MINIO_PUBLIC_ENDPOINT') ?? endpoint;

    this.s3 = new S3Client({
      forcePathStyle: true,
      region: 'us-east-1',
      endpoint,
      credentials: {
        accessKeyId: accessKey,
        secretAccessKey: secretKey,
      },
    });
  }

  async uploadToVault(
    file: Express.Multer.File,
    workspaceId: string,
    uploaderId: string,
  ) {
    await this.assertMembership(workspaceId, uploaderId);

    const key = `${workspaceId}/${Date.now()}-${file.originalname}`;

    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
      }),
    );

    const record = await this.prisma.vaultFile.create({
      data: {
        workspaceId,
        uploaderId,
        name: file.originalname,
        url: `${this.publicEndpoint}/${this.bucket}/${encodeURIComponent(key)}`,
        size: file.size,
        contentType: file.mimetype,
      },
    });

    return {
      id: record.id,
      name: record.name,
      url: record.url,
      size: record.size,
      contentType: record.contentType,
      createdAt: record.createdAt.toISOString(),
    };
  }

  async listRecentFiles(workspaceId: string, userId?: string, limit = 20) {
    if (userId) {
      await this.assertMembership(workspaceId, userId);
    }

    const files = await this.prisma.vaultFile.findMany({
      where: { workspaceId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { uploader: true },
    });

    return files.map((file) => ({
      id: file.id,
      name: file.name,
      url: file.url,
      size: file.size,
      contentType: file.contentType,
      uploadedAt: file.createdAt.toISOString(),
      uploader: {
        id: file.uploaderId,
        name: file.uploader.displayName ?? null,
        email: file.uploader.email,
      },
    }));
  }

  async getFile(fileId: string, userId?: string) {
    const file = await this.prisma.vaultFile.findUnique({
      where: { id: fileId },
      include: { uploader: true },
    });

    if (!file) {
      throw new ForbiddenException('File not found');
    }

    if (userId) {
      await this.assertMembership(file.workspaceId, userId);
    }

    return {
      id: file.id,
      name: file.name,
      url: file.url,
      size: file.size,
      contentType: file.contentType,
      uploadedAt: file.createdAt.toISOString(),
      uploader: {
        id: file.uploaderId,
        name: file.uploader.displayName ?? null,
        email: file.uploader.email,
      },
    };
  }

  async deleteFile(fileId: string, userId: string) {
    const file = await this.prisma.vaultFile.findUnique({
      where: { id: fileId },
    });

    if (!file) {
      throw new ForbiddenException('File not found');
    }

    await this.assertMembership(file.workspaceId, userId);

    // Check if user is uploader or has admin/owner role
    if (file.uploaderId !== userId) {
      const membership = await this.prisma.workspaceMember.findFirst({
        where: { workspaceId: file.workspaceId, userId },
      });

      if (!membership || (membership.role !== 'ADMIN' && membership.role !== 'OWNER')) {
        throw new ForbiddenException('Only the uploader or workspace admins can delete files');
      }
    }

    await this.prisma.vaultFile.delete({
      where: { id: fileId },
    });

    return { success: true };
  }

  private async assertMembership(workspaceId: string, userId: string) {
    const membership = await this.prisma.workspaceMember.findFirst({
      where: { workspaceId, userId },
    });

    if (!membership) {
      throw new ForbiddenException('User is not a member of this workspace');
    }
  }
}
