import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../database/prisma.service';
import { AuthTokenPayload, AuthUser } from './jwt-payload.interface';
import { compare } from 'bcrypt';
import { sign, verify } from 'jsonwebtoken';

@Injectable()
export class AuthService {
  private readonly tokenTtl = '12h';

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  private get jwtSecret(): string {
    const secret = this.config.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error('JWT_SECRET is not configured');
    }
    return secret;
  }

  private sanitizeUser(user: {
    id: string;
    email: string;
    displayName: string | null;
    passwordHash: string;
  }): AuthUser {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
    };
  }

  async validateUser(email: string, password: string): Promise<AuthUser> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await compare(password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.sanitizeUser(user);
  }

  issueToken(user: AuthUser): { token: string } {
    const payload: AuthTokenPayload = {
      sub: user.id,
      email: user.email,
      displayName: user.displayName,
    };

    const token = sign(payload, this.jwtSecret, { expiresIn: this.tokenTtl });
    return { token };
  }

  async login(email: string, password: string): Promise<{
    token: string;
    user: AuthUser;
  }> {
    const user = await this.validateUser(email, password);
    const { token } = this.issueToken(user);
    return { token, user };
  }

  verifyToken(token: string): AuthTokenPayload {
    try {
      const decoded = verify(token, this.jwtSecret);
      if (typeof decoded === 'string') {
        throw new UnauthorizedException('Invalid token');
      }
      return decoded as AuthTokenPayload;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}