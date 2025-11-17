import { Controller, Get } from "@nestjs/common";
import { TaskService } from "./task.service";

@Controller("system")  // single-level only
export class SystemController {
  constructor(private readonly taskService: TaskService) {}

  @Get("metrics")
  getMetrics() {
    return this.taskService.logMetric();
  }
}
