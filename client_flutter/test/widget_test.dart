import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo/models/legacy/legacy_message.dart';
import 'package:flo/services/chat_models.dart';
import 'package:flo/state/active_workspace_state.dart';
import 'package:flo/ui/views/chat_view.dart';
import 'package:provider/provider.dart';

void main() {
  test('LegacyMessage adapts modern attachments and reactions', () {
    final legacy = LegacyMessage(
      ChatMessage.fromJson({
        'id': 'message-1',
        'channelId': 'channel-1',
        'senderId': 'user-1',
        'content': 'Attached',
        'createdAt': '2026-05-01T10:30:00.000Z',
        'attachments': [
          {'id': 'file-1', 'name': 'brief.pdf', 'type': 'file', 'url': 'https://example.com/brief.pdf'},
        ],
        'reactions': {
          'like': ['user-2', 'user-3'],
        },
      }),
    );

    expect(legacy.attachments, ['https://example.com/brief.pdf']);
    expect(legacy.imageUrl, 'https://example.com/brief.pdf');
    expect(legacy.replyCount, 0);
    expect(legacy.reactions.single['count'], 2);
  });

  testWidgets('ChatView compatibility route renders', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ActiveWorkspaceState(),
        child: const MaterialApp(home: ChatView()),
      ),
    );

    expect(find.byType(ChatView), findsOneWidget);
  });
}
