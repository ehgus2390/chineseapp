import '../models/message.dart';

class ChatService {
  int _counter = 0;
  final Map<String, List<Message>> _messages = <String, List<Message>>{}; // threadId -> messages

  List<Message> getMessages(String threadId) => _messages[threadId] ?? <Message>[];

  Message send(String threadId, String senderId, String text) {
    final Message msg = Message(
      id: _nextId(),
      threadId: threadId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    addMessage(threadId, msg);
    return msg;
  }

  void addMessage(String threadId, Message message) {
    _messages.putIfAbsent(threadId, () => <Message>[]).add(message);
  }

  String _nextId() {
    _counter += 1;
    return _counter.toString();
  }
}
