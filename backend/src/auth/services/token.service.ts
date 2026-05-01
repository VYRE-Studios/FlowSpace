import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma.service';
import * as crypto from 'crypto';

@Injectable()
export class TokenService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {}

  generateVerificationToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  generateRefreshToken(): string {
    return crypto.randomBytes(40).toString('hex');
  }

  async saveVerificationToken(userId: string, token: string): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24); // 24 hours

    await this.prisma.verificationToken.create({
      data: { userId, token, expiresAt },
    });
  }

  async validateVerificationToken(token: string) {
    const verificationToken = await this.prisma.verificationToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!verificationToken || verificationToken.expiresAt < new Date()) {
      return null;
    }

    return verificationToken;
  }

  async deleteVerificationToken(token: string): Promise<void> {
    await this.prisma.verificationToken.delete({ where: { token } });
  }

  async saveRefreshToken(userId: string, token: string): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await this.prisma.refreshToken.create({
      data: { userId, token, expiresAt },
    });
  }

  async validateRefreshToken(token: string) {
    const refreshToken = await this.prisma.refreshToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!refreshToken || refreshToken.expiresAt < new Date()) {
      return null;
    }

    // Update last used
    await this.prisma.refreshToken.update({
      where: { id: refreshToken.id },
      data: { lastUsed: new Date() },
    });

    return refreshToken.user;
  }

  async revokeRefreshToken(token: string): Promise<void> {
    await this.prisma.refreshToken.deleteMany({ where: { token } });
  }
}
