import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/app_state.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._appState);

  final AppState _appState;

  Stream<int> unseenCountStream() {
    return _appState.watchUnseenNotificationsCount();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> inboxStream() {
    return _appState.watchNotificationsInbox();
  }

  Future<void> markAllSeen() async {
    await _appState.markNotificationsSeen();
  }
}
