import { Injectable, Logger } from "@nestjs/common";

@Injectable()
export class TaskService {
  private readonly logger = new Logger(TaskService.name);

  constructor() {
    this.logger.log("TaskService initialized (?-06 stub)");
  }

  logMetric() {
    return { ok: true, message: "Metrics stub active", phase: "?-06" };
  }
}
