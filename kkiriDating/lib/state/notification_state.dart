import 'package:flutter/foundation.dart';

class NotificationState extends ChangeNotifier {
  int _unreadChatCount = 0;

  int get unreadChatCount => _unreadChatCount;

  void incrementChatBadge() {
    _unreadChatCount += 1;
    notifyListeners();
  }

  void clearChatBadge() {
    if (_unreadChatCount == 0) return;
    _unreadChatCount = 0;
    notifyListeners();
  }
}
