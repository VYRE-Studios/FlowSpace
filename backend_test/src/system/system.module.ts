import { Module } from "@nestjs/common";
import { TaskService } from "./task.service";
import { SystemController } from "./system.controller";

@Module({
  providers: [TaskService],
  controllers: [SystemController],
})
export class SystemModule {}
