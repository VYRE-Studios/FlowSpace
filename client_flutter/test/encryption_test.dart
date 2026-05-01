import 'package:flutter_test/flutter_test.dart';
import 'package:flo/services/chat_models.dart';

void main() {
  test('ChatMessage parses backend message payloads', () {
    final message = ChatMessage.fromJson({
      'id': 'message-1',
      'channelId': 'channel-1',
      'senderId': 'user-1',
      'senderName': 'Ava',
      'content': 'Hello FlowSpace',
      'createdAt': '2026-05-01T10:30:00.000Z',
      'threadCount': 2,
      'reactions': {
        'like': ['user-2'],
      },
    });

    expect(message.id, 'message-1');
    expect(message.senderName, 'Ava');
    expect(message.threadCount, 2);
    expect(message.reactions?['like'], ['user-2']);
  });
}
