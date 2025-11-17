import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const threads = await prisma.chatThread.findMany({ take: 1 });
  if (threads.length > 0) {
    console.log('Chat seed skipped; threads already exist.');
    return;
  }

  const now = new Date();

  await prisma.chatThread.create({
    data: {
      title: 'General Discussion',
      messages: {
        create: [
          {
            senderId: 'user-001',
            senderName: 'Flowspace Operator',
            content: 'Welcome to Flowspace mission control.',
            createdAt: now,
          },
          {
            senderId: 'user-002',
            senderName: 'Mission Control',
            content: 'Copy that. Systems are green across the board.',
            createdAt: new Date(now.getTime() + 1000 * 60 * 2),
          },
        ],
      },
    },
  });

  await prisma.chatThread.create({
    data: {
      title: 'Design Ops',
      messages: {
        create: [
          {
            senderId: 'user-003',
            senderName: 'Design Pilot',
            content: 'Pushing the FVS-1.0 tweaks to staging.',
            createdAt: now,
          },
        ],
      },
    },
  });

  console.log('Chat seed complete.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

