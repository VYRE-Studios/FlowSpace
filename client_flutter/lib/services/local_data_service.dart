import 'dart:math';



class LocalDataService {
  static const _userKey = 'local.user';
  static const _workspacesKey = 'local.workspaces';

  static Future<Map<String, dynamic>> ensureUser() async {
    final cached = CacheService.read(_userKey);
    if (cached != null && cached.payload is Map) {
      return Map<String, dynamic>.from(cached.payload as Map);
    }

    final user = {
      'id': 'user-local-1',
      'email': 'ava@vyrevault.studio',
      'displayName': 'Ava Local',
    };

    await CacheService.write(_userKey, user);
    return user;
  }

  static Future<List<Map<String, dynamic>>> ensureWorkspaces() async {
    final cached = CacheService.read(_workspacesKey);
    if (cached != null && cached.payload is List) {
      return (cached.payload as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    final workspaceId = 'ws-local-1';
    final user = await ensureUser();

    final channels = [
      _createChannelMap(workspaceId, 'general', description: 'General updates'),
      _createChannelMap(workspaceId, 'engineering', description: 'Engineering discussions'),
    ];

    final workspaces = [
      {
        'id': workspaceId,
        'slug': 'flowspace-local',
        'name': 'Flowspace Local',
        'description': 'Offline snapshot workspace',
        'ownerId': user['id'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    await CacheService.write(_workspacesKey, workspaces);

    await CacheService.write('workspace.bootstrap', {
      'user': user,
      'workspaces': workspaces,
    });

    await CacheService.write('chat.channels.$workspaceId', channels);

    for (final channel in channels) {
      final channelId = channel['id'] as String;
      final messages = [
        _createMessageMap(
          channelId,
          user['id'] as String,
          content: 'Welcome to #${channel['name']}! This is cached content.',
        ),
      ];

      await CacheService.write('chat.channelDetail.$workspaceId.$channelId', {
        'channel': channel,
        'messages': messages,
      });
    }

    return workspaces;
  }

  static Future<Map<String, dynamic>> createWorkspace(
    String name, {
    String? description,
  }) async {
    final user = await ensureUser();
    final workspaces = await ensureWorkspaces();
    final workspaceId = _generateId(prefix: 'ws');

    final newWorkspace = {
      'id': workspaceId,
      'slug': name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      'name': name,
      'description': description ?? '',
      'ownerId': user['id'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final updated = [...workspaces, newWorkspace];
    await CacheService.write(_workspacesKey, updated);
    await CacheService.write('workspace.bootstrap', {
      'user': user,
      'workspaces': updated,
    });

    await CacheService.write('chat.channels.$workspaceId', <Map<String, dynamic>>[]);
    return newWorkspace;
  }

  static Future<Map<String, dynamic>> createChannel(
    String workspaceId,
    String name, {
    String? description,
  }) async {
    final channel = _createChannelMap(
      workspaceId,
      name,
      description: description,
    );

    final channels = await getChannels(workspaceId);
    final updatedChannels = [...channels, channel];
    await CacheService.write('chat.channels.$workspaceId', updatedChannels);

    await CacheService.write('chat.channelDetail.$workspaceId.${channel['id']}', {
      'channel': channel,
      'messages': <Map<String, dynamic>>[],
    });

    return channel;
  }

  static Future<List<Map<String, dynamic>>> getChannels(String workspaceId) async {
    await ensureWorkspaces();
    final cached = CacheService.read('chat.channels.$workspaceId');
    if (cached != null && cached.payload is List) {
      return (cached.payload as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> appendMessage(
    String workspaceId,
    String channelId,
    Map<String, dynamic> message,
  ) async {
    final detailKey = 'chat.channelDetail.$workspaceId.$channelId';
    final cached = CacheService.read(detailKey);
    if (cached != null && cached.payload is Map) {
      final map = Map<String, dynamic>.from(cached.payload as Map);
      final messages = (map['messages'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      messages.add(message);

      final channel = Map<String, dynamic>.from(map['channel'] as Map);
      channel['lastMessage'] = {
        'id': message['id'],
        'senderId': message['senderId'],
        'senderName': message['senderName'],
        'content': message['content'],
        'createdAt': message['createdAt'],
      };
      channel['updatedAt'] = message['createdAt'];

      await CacheService.write(detailKey, {
        'channel': channel,
        'messages': messages,
      });

      final channels = await getChannels(workspaceId);
      final updatedChannels = channels
          .map((item) => item['id'] == channelId ? channel : item)
          .toList();
      await CacheService.write('chat.channels.$workspaceId', updatedChannels);

      return {
        'channel': channel,
        'messages': messages,
      };
    } else {
      final map = {
        'channel': {
          'id': channelId,
          'name': 'channel',
          'description': '',
          'updatedAt': message['createdAt'],
          'lastMessage': {
            'id': message['id'],
            'senderId': message['senderId'],
            'senderName': message['senderName'],
            'content': message['content'],
            'createdAt': message['createdAt'],
          },
        },
        'messages': [message],
      };
      await CacheService.write(detailKey, map);
      return map;
    }
  }

  static Map<String, dynamic> _createChannelMap(
    String workspaceId,
    String name, {
    String? description,
  }) {
    final id = _generateId(prefix: 'ch');
    return {
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'description': description ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastMessage': null,
    };
  }

  static Map<String, dynamic> _createMessageMap(
    String channelId,
    String senderId, {
    required String content,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': _generateId(prefix: 'msg'),
      'channelId': channelId,
      'senderId': senderId,
      'senderName': 'Ava Local',
      'content': content,
      'attachments': <String>[],
      'createdAt': now,
    };
  }

  static Map<String, dynamic> createLocalMessage(
    String channelId,
    String senderId,
    String senderName,
    String content,
  ) {
    return _createMessageMap(
      channelId,
      senderId,
      content: content,
    )..['senderName'] = senderName;
  }

  static String _generateId({String prefix = 'id'}) {
    final rand = Random().nextInt(1 << 32);
    return '$prefix-$rand-${DateTime.now().millisecondsSinceEpoch}';
  }
}
