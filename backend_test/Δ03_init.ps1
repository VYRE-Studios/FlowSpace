# --- Δ-03 INITIALIZATION SCRIPT ---

# 1️⃣  Ensure PostgreSQL and Prisma packages are present
cd C:\FlowSpace\backend
npm install prisma @prisma/client --save

# 2️⃣  Initialize Prisma project
npx prisma init --datasource-provider postgresql

# 3️⃣  Write environment variables
@"
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/flowspace?schema=public"
NODE_ENV=development
PORT=4000
"@ | Set-Content -Encoding utf8 ".env"

# 4️⃣  Replace the auto-generated schema.prisma with our Δ-03 schema
@"
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model ProofLog {
  id          String   @id @default(cuid())
  phase       String
  message     String
  timestamp   DateTime @default(now())
}
"@ | Set-Content -Encoding utf8 "prisma\schema.prisma"

# 5️⃣  Generate Prisma client and push schema
npx prisma generate
npx prisma db push

# 6️⃣  Rewrite main.ts for Δ-03
@"
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Module, Controller, Get, Logger } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

@Controller('v1/db')
class DatabaseController {
  private readonly logger = new Logger('Δ-03-DB');
  @Get('health')
  async getHealth() {
    try {
      await prisma.$queryRaw\`SELECT 1\`;
      this.logger.log('✅ Database connection verified');
      return { ok: true, phase: 'Δ-03', db: 'connected' };
    } catch (error) {
      this.logger.error('❌ Database connection failed', error);
      return { ok: false, phase: 'Δ-03', error: error.message };
    }
  }
}

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [DatabaseController],
})
class AppModule {}

async function bootstrap() {
  const logger = new Logger('Δ-03');
  const app = await NestFactory.create(AppModule, { cors: true });
  app.setGlobalPrefix('api');
  const port = Number(process.env.PORT) || 4000;
  await app.listen(port);
  logger.log(\`🚀 Flowspace Δ-03 running on http://localhost:\${port}/api/v1/db/health\`);
}
bootstrap();
"@ | Set-Content -Encoding utf8 "src\main.ts"

# 7️⃣  Done
Write-Host "`n✅ Δ-03 initialization complete. Run 'npm run start:dev' to verify the database connection.`n"
