import 'package:uuid/uuid.dart';
import '../models/message.dart';

class ChatService {
  final _uuid = const Uuid();
  final Map<String, List<Message>> _messages = {}; // matchId -> messages

  List<Message> getMessages(String matchId) => _messages[matchId] ?? [];

  void send(String matchId, String senderId, String text) {
    final msg = Message(
      id: _uuid.v4(),
      matchId: matchId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(matchId, () => []).add(msg);
  }
}
