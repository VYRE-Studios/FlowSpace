import { INestApplication, Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { PrismaClient } from "@prisma/client";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit() {
    // Generate Prisma Client first (ensures types are up to date)
    await this.ensurePrismaClient();
    // Auto-run migrations on startup (silent, user-friendly)
    await this.runMigrations();
    await this.$connect();
  }

  private async ensurePrismaClient() {
    // Retry logic for Prisma Client generation (files might be locked during hot reload)
    const maxRetries = 3;
    const retryDelay = 1000; // 1 second
    
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Generate Prisma Client to ensure types match schema
        await execAsync("npx prisma generate", {
          cwd: process.cwd(),
          timeout: 15000,
        });
        if (attempt > 0) {
          this.logger.log("Prisma Client generated successfully (after retry)");
        } else {
          this.logger.debug("Prisma Client is up to date");
        }
        return; // Success
      } catch (error: any) {
        const isFileLockError = 
          error.message?.includes('EPERM') || 
          error.message?.includes('operation not permitted') ||
          error.message?.includes('locked');
        
        if (isFileLockError && attempt < maxRetries - 1) {
          // Files are locked, wait and retry
          this.logger.debug(`Prisma Client files locked, retrying in ${retryDelay}ms... (attempt ${attempt + 1}/${maxRetries})`);
          await new Promise(resolve => setTimeout(resolve, retryDelay));
          continue;
        }
        
        // Non-fatal: Prisma Client might already be generated or files still locked
        if (isFileLockError) {
          this.logger.debug("Prisma Client generation skipped (files locked, using existing client)");
        } else {
          this.logger.debug("Prisma Client generation skipped (may already be up to date)");
        }
        return; // Give up after retries
      }
    }
  }

  private async runMigrations() {
    try {
      this.logger.log("Auto-syncing database schema...");
      
      // Use db push for automatic schema synchronization
      // This is user-friendly: no migration files needed, handles drift automatically
      // Perfect for end users who just want "double-click and it works"
      const { stdout, stderr } = await execAsync(
        "npx prisma db push --accept-data-loss --skip-generate",
        {
          cwd: process.cwd(),
          env: { ...process.env },
          // Suppress prompts - fully automatic
          timeout: 30000, // 30 second timeout
        }
      );
      
      if (stdout) {
        if (stdout.includes("Your database is now in sync")) {
          this.logger.log("Database schema synchronized");
        } else if (stdout.includes("Already in sync")) {
          this.logger.debug("Database schema is up to date");
        } else {
          // Only log if there's actual output (not just empty lines)
          const trimmed = stdout.trim();
          if (trimmed) {
            this.logger.debug(trimmed);
          }
        }
      }
      
      // Ignore warnings about data loss in dev (user-friendly)
      if (stderr && !stderr.includes("warning") && stderr.trim()) {
        this.logger.debug(stderr.trim());
      }

      this.logger.log("Database ready");
    } catch (error: any) {
      // Don't crash the app - log and continue
      // User can restart if there are issues, and it will retry
      if (error.message?.includes("timeout")) {
        this.logger.warn("Database sync timed out - will retry on next startup");
      } else {
        this.logger.error(
          `Database sync failed (non-fatal): ${error.message?.split('\n')[0] || 'Unknown error'}`,
        );
      }
      this.logger.warn(
        "Application will continue. If you see database errors, restart the application."
      );
    }
  }

  async enableShutdownHooks(app: INestApplication) {
    // TypeScript sometimes infers 'never' for the event type, so cast to any.
    (this as any).$on("beforeExit", async () => {
      await app.close();
    });
  }
}
