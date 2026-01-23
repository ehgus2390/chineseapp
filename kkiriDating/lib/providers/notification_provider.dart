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

  Future<void> createNotification({
    required String userId,
    required String type,
    required String? fromUid,
    required String? refId,
  }) async {
    await _appState.createNotification(
      userId: userId,
      type: type,
      fromUid: fromUid,
      refId: refId,
    );
  }
}
