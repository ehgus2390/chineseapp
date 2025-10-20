import '../models/message.dart';

class ChatService {
  int _counter = 0;
  final Map<String, List<Message>> _messages = <String, List<Message>>{}; // matchId -> messages

  List<Message> getMessages(String matchId) => _messages[matchId] ?? [];

  void send(String matchId, String senderId, String text) {
    final msg = Message(
      id: _nextId(),
      matchId: matchId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(matchId, () => <Message>[]).add(msg);
  }

  String _nextId() {
    _counter += 1;
    return _counter.toString();
  }
}
