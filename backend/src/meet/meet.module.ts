import { Module } from '@nestjs/common';

import { MeetController } from './meet.controller';
import { MeetService } from './meet.service';
import { PrismaModule } from '../database/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [MeetController],
  providers: [MeetService],
  exports: [MeetService],
})
export class MeetModule {}
