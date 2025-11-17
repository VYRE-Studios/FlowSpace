import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MeetController } from './meet/meet.controller';
import { ChatModule } from './modules/chat/chat.module';
import { SystemModule } from './system/system.module';
import { WorkspacesController } from './workspaces/workspaces.controller';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), SystemModule, ChatModule],
  controllers: [AppController, WorkspacesController, MeetController],
  providers: [AppService],
})
export class AppModule {}
