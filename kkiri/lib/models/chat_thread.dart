class ChatThread {
  ChatThread({
    required this.id,
    required this.friendId,
    required this.updatedAt,
    this.lastMessage,
  });

  final String id;
  final String friendId;
  DateTime updatedAt;
  String? lastMessage;
}
