import { Body, Controller, Post, Get, Query, BadRequestException, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt.guard';
import { TokenService } from './services/token.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly tokenService: TokenService,
  ) {}

  @Post('register')
  async register(
    @Body()
    body: {
      email?: string;
      password?: string;
      name?: string;
      nickname?: string;
      workspaceName?: string; // Optional, for future workspace creation
    },
  ) {
    if (!body.email || !body.password || !body.name) {
      throw new BadRequestException('Email, password, and name are required');
    }

    return this.authService.register(body.email, body.password, body.name, body.nickname);
  }

  @Post('login')
  async login(
    @Body()
    body: {
      email?: string;
      password?: string;
    },
  ) {
    if (!body.email || !body.password) {
      throw new BadRequestException('Email and password are required');
    }

    return this.authService.login(body.email, body.password);
  }

  // NEW ENDPOINTS:

  @Post('register-with-verification')
  async registerWithVerification(@Body() body: {
    email?: string;
    password?: string;
    name?: string;
    nickname?: string;
  }) {
    if (!body.email || !body.password || !body.name) {
      throw new BadRequestException('Email, password, and name are required');
    }

    return this.authService.registerWithVerification(
      body.email,
      body.password,
      body.name,
      body.nickname,
    );
  }

  @Get('verify-email')
  async verifyEmail(@Query('token') token: string) {
    if (!token) {
      throw new BadRequestException('Token is required');
    }

    return this.authService.verifyEmail(token);
  }

  @Post('login-with-remember-me')
  async loginWithRememberMe(@Body() body: {
    email?: string;
    password?: string;
    rememberMe?: boolean;
  }) {
    if (!body.email || !body.password) {
      throw new BadRequestException('Email and password are required');
    }

    return this.authService.loginWithRememberMe(
      body.email,
      body.password,
      body.rememberMe || false,
    );
  }

  @Post('refresh')
  async refresh(@Body() body: { refreshToken?: string }) {
    if (!body.refreshToken) {
      throw new BadRequestException('Refresh token is required');
    }

    return this.authService.refreshAccessToken(body.refreshToken);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  async logout(@Body() body: { refreshToken?: string }) {
    if (body.refreshToken) {
      await this.tokenService.revokeRefreshToken(body.refreshToken);
    }

    return { message: 'Logged out successfully' };
  }
}
