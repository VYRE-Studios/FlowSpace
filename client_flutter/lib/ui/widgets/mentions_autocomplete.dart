import 'package:flutter/material.dart';

class MentionsAutocomplete extends StatelessWidget {
  final List<String> userNames;
  final Function(String) onUserSelected;
  final String searchQuery;

  const MentionsAutocomplete({
    Key? key,
    required this.userNames,
    required this.onUserSelected,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredUsers = userNames
        .where((name) => name.toLowerCase().contains(searchQuery.toLowerCase()))
        .take(5)
        .toList();

    if (filteredUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final userName = filteredUsers[index];
          return InkWell(
            onTap: () => onUserSelected(userName),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.primaries[
                        userName.hashCode % Colors.primaries.length],
                    child: Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
