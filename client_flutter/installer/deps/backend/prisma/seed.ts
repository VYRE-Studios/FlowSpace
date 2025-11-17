import { PrismaClient } from '@prisma/client';
import { hashSync } from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const existing = await prisma.workspace.count();
  if (existing > 0) {
    console.log('Workspace seed skipped; records already exist.');
    return;
  }

  const passwordHash = hashSync('flowspace123', 10);

  const [ava, toren] = await Promise.all([
    prisma.user.create({
      data: {
        email: 'ava@vyrevault.studio',
        passwordHash,
        displayName: 'Ava Theron',
      },
    }),
    prisma.user.create({
      data: {
        email: 'toren@vyrevault.studio',
        passwordHash,
        displayName: 'Toren Vale',
      },
    }),
  ]);

  const workspace = await prisma.workspace.create({
    data: {
      slug: 'vyrevault-studios',
      name: 'VyreVault Studios',
      description: 'Primary mission control workspace.',
      ownerId: ava.id,
      members: {
        create: [
          { userId: ava.id, role: 'OWNER' },
          { userId: toren.id, role: 'MEMBER' },
        ],
      },
    },
  });

  const [operations, design] = await Promise.all([
    prisma.channel.create({
      data: {
        workspaceId: workspace.id,
        name: 'mission-ops',
        description: 'Operations and stand-up coordination',
      },
    }),
    prisma.channel.create({
      data: {
        workspaceId: workspace.id,
        name: 'design-lab',
        description: 'Design systems and visual updates',
      },
    }),
  ]);

  await prisma.chatMessage.createMany({
    data: [
      {
        channelId: operations.id,
        senderId: ava.id,
        content: 'Mission control is green. Syncing Delta-13 rollout.',
      },
      {
        channelId: operations.id,
        senderId: toren.id,
        content: 'Copy that. Standing by for vault integration check.',
      },
      {
        channelId: design.id,
        senderId: ava.id,
        content: 'Pushing updated UI spec to the vault in five.',
      },
    ],
  });

  await prisma.vaultFile.create({
    data: {
      workspaceId: workspace.id,
      uploaderId: ava.id,
      name: 'flowspace-spec-v1.pdf',
      url: 'https://example.com/files/flowspace-spec-v1.pdf',
      size: 524288,
      contentType: 'application/pdf',
    },
  });

  console.log('Workspace seed complete.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
