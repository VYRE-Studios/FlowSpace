import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

interface KratosWhoAmIResponse {
  id: string;
  active: boolean;
  authenticated_at: string;
  issued_at: string;
  identity: {
    id: string;
    traits?: Record<string, any>;
    [key: string]: any;
  };
  [key: string]: any;
}

@Injectable()
export class KratosService {
  private readonly publicUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.publicUrl =
      this.configService.get<string>('KRATOS_PUBLIC_URL') ??
      'http://localhost:4455';
  }

  async whoAmI({
    cookie,
    sessionToken,
  }: {
    cookie?: string;
    sessionToken?: string;
  }): Promise<KratosWhoAmIResponse> {
    if (!cookie && !sessionToken) {
      throw new UnauthorizedException('Missing Kratos session');
    }

    try {
      const headers: Record<string, string> = {};
      if (cookie) {
        headers.cookie = cookie;
      }
      if (sessionToken) {
        headers['x-session-token'] = sessionToken;
      }

      const { data } = await axios.get<KratosWhoAmIResponse>(
        `${this.publicUrl}/sessions/whoami`,
        { headers },
      );

      return data;
    } catch (error) {
      throw new UnauthorizedException('Invalid Kratos session');
    }
  }
}

