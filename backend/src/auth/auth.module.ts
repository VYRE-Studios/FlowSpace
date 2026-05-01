import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { PrismaModule } from '../database/prisma.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt.guard';
import { KratosService } from './kratos.service';
import { KratosSessionGuard } from './kratos-session.guard';
import { TokenService } from './services/token.service';
import { EmailService } from './services/email.service';

@Module({
  imports: [ConfigModule, PrismaModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtAuthGuard,
    KratosService,
    KratosSessionGuard,
    TokenService,
    EmailService,
  ],
  exports: [
    AuthService,
    JwtAuthGuard,
    KratosService,
    KratosSessionGuard,
    TokenService,
    EmailService,
  ],
})
export class AuthModule {}
