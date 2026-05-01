import '../models/mention.dart';

class MentionParser {
  // Regex to match @mentions (alphanumeric, underscores, hyphens)
  static final RegExp _mentionPattern = RegExp(r'@(\w[\w\-]*\w|\w)');
  
  /// Parse mentions from text
  /// 
  /// Returns list of potential mention strings (without @)
  static List<String> extractMentionStrings(String text) {
    final matches = _mentionPattern.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }
  
  /// Parse mentions with positions from text
  /// 
  /// Returns list of Mention objects with start/end positions
  /// Note: userId and avatarUrl need to be resolved separately
  static List<Mention> parseMentions(
    String text,
    Map<String, String> userIdMap, // displayName -> userId
  ) {
    final mentions = <Mention>[];
    final matches = _mentionPattern.allMatches(text);
    
    for (final match in matches) {
      final displayName = match.group(1)!;
      final userId = userIdMap[displayName.toLowerCase()];
      
      if (userId != null) {
        mentions.add(Mention(
          userId: userId,
          displayName: displayName,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    return mentions;
  }
  
  /// Check if text contains any mentions
  static bool hasMentions(String text) {
    return _mentionPattern.hasMatch(text);
  }
  
  /// Get mention at specific cursor position
  static String? getMentionAtPosition(String text, int cursorPosition) {
    // Find the @mention that the cursor is within
    final matches = _mentionPattern.allMatches(text);
    
    for (final match in matches) {
      if (cursorPosition >= match.start && cursorPosition <= match.end) {
        return match.group(1);
      }
    }
    
    // Check if cursor is immediately after @ symbol
    if (cursorPosition > 0 && text[cursorPosition - 1] == '@') {
      return '';
    }
    
    // Check if we're in the middle of typing a mention
    if (cursorPosition > 0) {
      final beforeCursor = text.substring(0, cursorPosition);
      final lastAtIndex = beforeCursor.lastIndexOf('@');
      
      if (lastAtIndex != -1) {
        final afterAt = beforeCursor.substring(lastAtIndex + 1);
        
        // Check if there's only valid mention characters after @
        if (RegExp(r'^[\w\-]*$').hasMatch(afterAt)) {
          return afterAt;
        }
      }
    }
    
    return null;
  }
  
  /// Replace mention text with formatted mention
  static String replaceMentionAtPosition(
    String text,
    int cursorPosition,
    String displayName,
  ) {
    // Find the start of the mention being typed
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    
    if (lastAtIndex == -1) return text;
    
    // Replace from @ to cursor position
    final before = text.substring(0, lastAtIndex);
    final after = text.substring(cursorPosition);
    
    return '$before@$displayName$after';
  }
  
  /// Get cursor position after inserting mention
  static int getCursorPositionAfterMention(
    String originalText,
    int originalCursorPosition,
    String displayName,
  ) {
    final beforeCursor = originalText.substring(0, originalCursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    
    if (lastAtIndex == -1) return originalCursorPosition;
    
    // New cursor position is after @displayName and space
    return lastAtIndex + displayName.length + 2; // +2 for @ and space
  }
  
  /// Highlight mentions in text for display
  static List<TextSegment> segmentTextWithMentions(
    String text,
    List<Mention> mentions,
  ) {
    if (mentions.isEmpty) {
      return [TextSegment(text: text, isMention: false)];
    }
    
    // Sort mentions by start position
    final sortedMentions = List<Mention>.from(mentions)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    final segments = <TextSegment>[];
    int currentIndex = 0;
    
    for (final mention in sortedMentions) {
      // Add text before mention
      if (mention.startIndex > currentIndex) {
        segments.add(TextSegment(
          text: text.substring(currentIndex, mention.startIndex),
          isMention: false,
        ));
      }
      
      // Add mention segment
      segments.add(TextSegment(
        text: text.substring(mention.startIndex, mention.endIndex),
        isMention: true,
        mention: mention,
      ));
      
      currentIndex = mention.endIndex;
    }
    
    // Add remaining text
    if (currentIndex < text.length) {
      segments.add(TextSegment(
        text: text.substring(currentIndex),
        isMention: false,
      ));
    }
    
    return segments;
  }
  
  /// Check if current user is mentioned
  static bool isCurrentUserMentioned(
    List<Mention> mentions,
    String currentUserId,
  ) {
    return mentions.any((m) => m.userId == currentUserId);
  }
}

class TextSegment {
  final String text;
  final bool isMention;
  final Mention? mention;
  
  TextSegment({
    required this.text,
    required this.isMention,
    this.mention,
  });
}
