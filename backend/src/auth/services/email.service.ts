import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private config: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.config.get('SMTP_HOST'),
      port: this.config.get('SMTP_PORT'),
      secure: false,
      auth: {
        user: this.config.get('SMTP_USER'),
        pass: this.config.get('SMTP_PASSWORD'),
      },
    });
  }

  async sendVerificationEmail(email: string, displayName: string, token: string): Promise<void> {
    const verificationUrl = `${this.config.get('FRONTEND_URL')}/verify-email?token=${token}`;

    try {
      await this.transporter.sendMail({
        from: `"${this.config.get('FROM_NAME')}" <${this.config.get('FROM_EMAIL')}>`,
        to: email,
        subject: 'Verify Your FLŌ Account',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #333;">Welcome to FLŌ, ${displayName}!</h1>
            <p>Please verify your email address by clicking the button below:</p>
            <div style="margin: 30px 0;">
              <a href="${verificationUrl}" 
                 style="background-color: #4F46E5; color: white; padding: 12px 24px; 
                        text-decoration: none; border-radius: 6px; display: inline-block;">
                Verify Email Address
              </a>
            </div>
            <p>Or copy this link: <a href="${verificationUrl}">${verificationUrl}</a></p>
            <p style="color: #999; font-size: 12px; margin-top: 40px;">
              This link expires in 24 hours.
            </p>
          </div>
        `,
      });

      this.logger.log(`Verification email sent to ${email}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to send verification email: ${errorMessage}`);
      throw new Error('Failed to send verification email');
    }
  }
}
